#!/bin/bash

# Version 1
# License Type: GNU GENERAL PUBLIC LICENSE, Version 3
# Author:
# Rodrigo Tomonari Muino / https://github.com/rodrigotomonari
# Description:
# Grant user ssh access to domain
# Users public key should be stored in keys folder. The key filename should be the username and the key comment
# has to be the username too.
# IE:
# filename: keys/john.doe
# ssh-rsa AAAAAAA... john.doe
#
# TODO:
# - Remove comment obligation
# - Read $VHOST_DIR from config vars
# - Add update function

VHOST_DIR="/home/vhosts"

SCRIPT=$(readlink -f "$0") 

BASEDIR=$(dirname ${SCRIPT})

KEYS_DIR=${BASEDIR}/keys

# Import functions
. ${BASEDIR}/utils/log.sh
. ${BASEDIR}/utils/domain.sh

# Check parameters
function options_check()
{
    if [ -z "${user}" ]
    then
        log_error "You must specify the user"
        log_blank

        print_usage
        exit 1
    fi

    if [ -z "${domain}" ]
    then
        log_error "You must specify the domain"
        log_blank

        print_usage
        exit 1
    fi

    file_key_exist?

    if [ $? -ne 0 ]
    then
        log_error "Key: ${KEYS_DIR}/${user} not found"
        exit 1
    fi

    domain_exist? ${domain}

    if [ $? -ne 0 ]
    then
        log_error "Domain: ${domain} does not exist"
        exit 1
    fi
}

function create_vhost_ssh_structure()
{
    if [ ! -d "${VHOST_DIR}/${domain}/.ssh/" ]
    then
        log "- Creating ${VHOST_DIR}/${domain}/.ssh/"
        mkdir ${VHOST_DIR}/${domain}/.ssh/
        set_ssh_dir_perms
    fi

    if [ ! -f "${VHOST_DIR}/${domain}/.ssh/authorized_keys" ]
    then
        log "- Creating ${VHOST_DIR}/${domain}/.ssh/authorized_keys"
        touch ${VHOST_DIR}/${domain}/.ssh/authorized_keys
        chown root:root ${VHOST_DIR}/${domain}/.ssh/authorized_keys
        set_authorized_keys_perms
    fi
}

function file_key_exist?()
{
    [ ! -f "${BASEDIR}/keys/${user}" ] && return 1

    return 0
}

function set_ssh_dir_perms()
{
    chmod 711 ${VHOST_DIR}/${domain}/.ssh/
}

function set_authorized_keys_perms()
{
    chmod 444 ${VHOST_DIR}/${domain}/.ssh/authorized_keys
}

function user_has_permission?()
{
    # Check if user already has access
    count=$(grep -c ${user} "${VHOST_DIR}/${domain}/.ssh/authorized_keys")

    if [ ${count} -gt 0 ]
    then
        return 0
    fi

    return 1
}

function grant_permission()
{
    cat ${KEYS_DIR}/${user} >> "${VHOST_DIR}/${domain}/.ssh/authorized_keys"
}

function main
{
    log "- Verify if user ${user} already has ssh permission"
    user_has_permission? && log_error "- User ${user} already has ssh permission" && exit 1
    log "- Good to go"
    grant_permission
    user_has_permission? && log_success "- Permission granted" && exit 0

    log_error "Something went wrong"
    exit 1
}

function print_usage()
{
    echo "-- Enable SSH KEY --"
    echo ""
    echo "Use: $0 [options] -d <domain> -u <user>"
    echo ""
    echo "Options:"
    echo "-d : Domain name"
    echo "-u : User name"
    echo "-c : Check if user has permission"
    echo ""
    exit 1
}

while getopts "u:d:ch?" options; do
  case ${options} in
    u ) user=$OPTARG;;
    d ) domain=$OPTARG;;
    c ) check=1;;
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done

options_check

create_vhost_ssh_structure

if [ "${check}" == "1" ]
then
    if $(user_has_permission?)
    then
        log_success "${user} has ssh permission at ${domain}"
        exit 0
    else
        log_error "${user} does not have ssh permission at ${domain}"
        exit 1
    fi
fi

main

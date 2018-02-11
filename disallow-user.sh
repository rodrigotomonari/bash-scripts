#!/bin/bash

VHOST_DIR="/home/vhosts"

SCRIPT=$(readlink -f "$0") 

BASEDIR=$(dirname ${SCRIPT})

# Import functions
. ${BASEDIR}/utils/log.sh
. ${BASEDIR}/utils/domain.sh

ask_confirmation=1

# Check parameters
function options_check()
{
    if [ -z ${user} ]
    then
        log_error "You must specify the user"
        log_blank

        print_usage
        exit 1
    fi

    if [ -n ${domain} ]
    then
        domain_exist? ${domain}

        if [ $? -ne 0 ]
        then
            log_error "Domain: ${domain} does not exist"
            exit 1
        fi
    fi

    if [ -z ${domain} ] && [ ${ask_confirmation} -eq 1 ]
    then
        echo "Do you really want to disallow ${user} at all domains?"
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) break;;
                No ) exit;;
            esac
        done
    fi
}

function disallow_user?()
{
    local domain

    user=$1
    domain=$2

    sed -i "/${user}/d" "${VHOST_DIR}/${domain}/.ssh/authorized_keys"

    log_success "- Permission for ${user} at ${domain} removed"
}

function main()
{
    if [ -n "${domain}" ]
    then
        disallow_user? ${user} ${domain}
        exit 0
    fi

    if [ -z "${domain}" ]
    then
        log "Search domains..."
        for domain in `ls ${VHOST_DIR}`
        do
            if [ -e "${VHOST_DIR}/${domain}/.ssh/authorized_keys" ]
            then
                ${BASEDIR}/allow-user.sh -c -u ${user} -d ${domain} > /dev/null
                if [ $? -eq 0 ]
                then
                    if [ ${ask_confirmation} -eq 1 ]
                    then
                        log_warn "Do you really want to disallow ${user} at domain: ${domain}?"
                        select yn in "Yes" "No"; do
                            case $yn in
                                Yes ) disallow_user? ${user} ${domain}; break;;
                                No ) break;;
                            esac
                        done
                    else
                        disallow_user? ${user} ${domain}
                    fi
                fi
            fi
        done

        exit 0
    fi
}

function print_usage()
{
    echo "-- Disable SSH KEY --"
    echo ""
    echo "Use: $0 -u <user>"
    echo ""
    echo "Options:"
    echo "-d : Domain name"
    echo "-y : Do not ask confirmation"
    echo ""
    exit 1
}

while getopts "u:d:yh?" options; do
    case ${options} in
        u ) user=$OPTARG;;
        d ) domain=$OPTARG;;
        y ) ask_confirmation=0;;
        h ) print_usage;;
        \? ) print_usage;;
        * ) print_usage;;
    esac
done

options_check

main

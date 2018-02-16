#!/usr/bin/env bash

VHOSTS_DIR="/home/vhosts"

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname ${SCRIPT})

# Import functions
. ${BASEDIR}/utils/log.sh
. ${BASEDIR}/utils/domain.sh

function options_check()
{
    if [ -z "${domain}" ]
    then
        log_error "You must specify the domain"
        log_blank

        print_usage
        exit 1
    fi

    domain_exist? ${domain}

    if [ $? -ne 0 ]
    then
        log_error "Domain: ${domain} does not exist"
        exit 1
    fi
}

function install()
{
    log "Creating sftp group"
    groupadd sftp

    echo ""

    log_warn "Comment in /etc/ssh/sshd_config the line:"
    echo "# Subsystem sftp /usr/lib/openssh/sftp-server"

    echo ""

    log_warn "And add the configuration bellow:"
    echo -e "Subsystem sftp internal-sftp"
    echo -e "Match Group sftp"
    echo -e '\tChrootDirectory %h'
    echo -e '\tForceCommand internal-sftp'
    echo -e '\tAllowTCPForwarding no'
    echo -e '\tX11Forwarding no'

    exit 0
}

function print_usage()
{
    echo "-- SFTP User --"
    echo ""
    echo "Use: $0 [options] -d <domain>"
    echo ""
    echo "Options:"
    echo "-d : Domain name"
    echo ""
    exit 1
}

function main()
{
    [ ! -d  ${VHOSTS_DIR}/${domain}/public ] && log_error "Domain public folder does not exist" && exit 1

    [ ! $(getent group sftp) ] && log_error "SFTP group does not exist. Run \"$0 -i\" to create and install." && exit

    user=$(stat -c '%U' ${VHOSTS_DIR}/${domain}/public)

    log "Changing domain home permissions"

    chown root:root ${VHOSTS_DIR}/${domain}
    chmod 755 ${VHOSTS_DIR}/${domain}

    log "Adding user to sftp group"

    adduser ${user} sftp
}

while getopts "d:ih?" options; do
  case ${options} in
    d ) domain=$OPTARG;;
    i ) install;;
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done

options_check

main

#!/bin/bash

# Version 2
# License Type: GNU GENERAL PUBLIC LICENSE, Version 3
# Author:
# Rodrigo Tomonari Muino / https://github.com/rodrigotomonari
# Description:
# Restart fpm service
# Use this script to restart fpm service
# Also use the -s option to check service status. Many information in systemd system.

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname ${SCRIPT})

status=0

# Import functions
. ${BASEDIR}/utils/log.sh

if [ "$(lsb_release -r -s)" = "14.04" ]
then
    is_systemd=0
else
    is_systemd=1
fi

function main()
{
    if [ "$is_systemd" -eq 0 ]; then
        service_list=$(initctl list | grep php | grep fpm | cut -d" " -f1)
    else
        service_list=$(systemctl list-unit-files | grep php | grep fpm | cut -d" " -f1 | sed -e 's/\.service$//')
    fi

    if [ -n "${domain}" ]
    then
        service_list=$(echo "${service_list}" | grep ${domain})
    fi

    for domain in ${service_list}
    do
        if [ "${status}" -eq "0" ]
        then
            log_warn "Restarting ${domain}"
            service ${domain} restart
        else
            log_success "Status ${domain}"
            service ${domain} status
        fi
    done
}

function print_usage()
{
    echo "-- Restart FPM --"
    echo ""
    echo "Use: $0 [options]"
    echo ""
    echo "Options:"
    echo "-d : Domain name"
    echo "-s : Check status instead of restart"
    echo ""
    exit 1
}

while getopts "d:sh?" options; do
    case ${options} in
        d ) domain=$OPTARG;;
        s ) status=1;;
        h ) print_usage;;
        \? ) print_usage;;
        * ) print_usage;;
    esac
done

main

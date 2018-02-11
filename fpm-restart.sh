#!/bin/bash

# Version 2
# License Type: GNU GENERAL PUBLIC LICENSE, Version 3
# Author:
# Rodrigo Tomonari Muino / https://github.com/rodrigotomonari
# Description:
# Restart fpm service
# Use this script to restart fpm service

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname ${SCRIPT})

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
        log "Restarting ${domain}"
        service ${domain} restart
    done
}

function print_usage()
{
    echo "-- Restart FPM --"
    echo ""
    echo "Use: $0 -u <user>"
    echo ""
    echo "Options:"
    echo "-d : Domain name"
    echo ""
    exit 1
}

while getopts "u:d:yh?" options; do
    case ${options} in
        d ) domain=$OPTARG;;
        h ) print_usage;;
        \? ) print_usage;;
        * ) print_usage;;
    esac
done

main

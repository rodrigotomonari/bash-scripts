#!/bin/bash

# Version 2
# License Type: GNU GENERAL PUBLIC LICENSE, Version 3
# Author:
# Rodrigo Tomonari Muino / https://github.com/rodrigotomonari
# Description:
# Configure a redirect domain in Apache

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname ${SCRIPT})

# Import functions
. ${BASEDIR}/utils/log.sh
. ${BASEDIR}/utils/domain.sh

force=0

# Check parameters
function options_check()
{
    if [ -z "${domain}" ]
    then
        log_error "You must specify the domain"
        log_blank

        print_usage
        exit 1
    fi

    if [ -z "${redirect_to}" ]
    then
        log_error "You must specify the redirect URL"
        log_blank

        print_usage
        exit 1
    fi
}

function main()
{
    if $(apache_vhost_exist? ${domain})
    then
        if [ ${force} -eq 1 ]
        then
            log_warn "Vhost file already exist. Overwriting..."
        else
            log_error "Vhost file already exist. Use -f to overwrite"
            exit 1
        fi
    fi

    log "Configuring vhost"
    vhost_file="/etc/apache2/sites-available/${domain}.conf"
    cat ${BASEDIR}/redirect_domain_files/TEMPLATE_VHOSTS > ${vhost_file}
    replace_keys ${vhost_file}

    log "Activating vhost"
    a2ensite ${domain}

    log "Testing apache2 config files"
    apache2ctl configtest &> /dev/null
    if [ $? -ne 0 ]
    then
        log_error "*** ERROR Vhost Conf ***"
        exit 1
    else
      log "Config passed"
      log_success "service apache2 reload"
    fi

    exit 0
}

function print_usage()
{
    echo "-- ADD REDIRECT VHOST --"
    echo ""
    echo "Use: $0 [options] -d <domain> -r <redirect_to>"
    echo "IE: $0 -d exemple.com -r http://anothersite.com/blog"
    echo "Options:"
    echo "-f : force"
    echo ""
    exit 1
}

function replace_keys() {
    sed -i "s/DOMAIN/$domain/g" $1
    sed -i "s/REDIRECT_TO/${redirect_to//\//\\/}/g" $1
}

while getopts "d:r:fh?" options; do
  case ${options} in
    d ) domain=$OPTARG;;
    r )
        redirect_to=$OPTARG
        redirect_to=$(echo ${redirect_to%/}) # Remove trailing slash
        ;;
    f ) force=1;;
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done

options_check

main

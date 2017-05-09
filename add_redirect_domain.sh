#!/bin/bash

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname $SCRIPT)

force=0
php_support=1

function print_usage()
{
    echo "-- Add vhost --"
    echo ""
    echo "Use: $0 [options] -d <domain> -r <redirect_to>"
    echo "IE: $0 -d exemple.com -r http://royalpixel.tv/blog"
    echo "Options:"
    echo "-f : force"
    echo ""
    exit 1
}

function log()
{
    echo "--- $1"
}

function replace_keys() {
    sed -i "s/DOMAIN/$domain/g" $1
    sed -i "s/REDIRECT_TO/${redirect_to//\//\\/}/g" $1
}

while getopts "d:r:fh?" options; do
  case $options in
    d ) domain=$OPTARG;;
    r ) redirect_to=$OPTARG;;
    f ) force=1;;
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done

[ -z $domain ] && echo "You must specify the domain" && exit 1

[ -z $redirect_to ] && echo "You must specify the redirect_to" && exit 1

# Remove trailing slash
redirect_to=`echo ${redirect_to%/}`

log "Configuring vhosts"

vhost_file="/etc/apache2/sites-available/${domain}.conf"

if [ $force -eq 1 -o ! -f  $vhost_file ]; then
   cat ${BASEDIR}/redirect_domain_files/TEMPLATE_VHOSTS > $vhost_file
   replace_keys $vhost_file
elif [ -f $vhost_file ]; then
   log "--- Vhosts file already exist. Use -f to overwrite"
fi

log "Activating Vhost"
a2ensite $domain

log "Test apache2 config files"
apache2ctl configtest &> /dev/null
apache_test=$? 
if [ $apache_test -ne 0 ]; then
    log "*** ERROR Vhost Conf ***---"
fi

exit 0

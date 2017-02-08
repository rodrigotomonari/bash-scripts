#!/bin/bash

VHOSTS_DIR="/home/vhosts"

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname $SCRIPT)

php_support=1

function print_usage()
{
        echo "-- Disable Vhost --"
        echo ""
        echo "Use: $0 [options] -d <domain>"
        echo ""
        echo "Options:"
	echo "-u : Use a custom user"
	echo "-p : No PHP support"
        echo ""
        exit 1
}

function log()
{
	echo "--- $1"
}

while getopts "d:u:fph?" options; do
  case $options in
    d ) domain=$OPTARG;;
    u ) user=$OPTARG;;
    p ) php_support=0;; 
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done

[ -z $domain ] && echo "You must specify the domain" && exit 1

[ -z $user ] && user=$domain

a2dissite $domain

if [ $php_support -eq 1 ]; then
	service php5-fpm-${domain} stop
	[ ! -d /root/disabled.services ] && mkdir /root/disabled.services
	mv /etc/init/php5-fpm-${domain}.conf /root/disabled.services/
fi

apache2ctl configtest

echo "service apache2 reload"


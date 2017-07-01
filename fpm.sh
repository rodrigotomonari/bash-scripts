#!/bin/bash

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname $SCRIPT)

force=0
restart=0
print_service=0

function print_usage()
{
  echo "-- PHP FPM STATUS --"
  echo ""
  echo "Use: $0 [options] -d <domain>"
  echo "IE: $0 -d exemple.com"
  echo "Options:"
  echo "-r : Restart"
  echo "-p : Print service"
  exit 1
}

function log()
{
  echo "--- $1"
}

while getopts "d:rph?" options; do
  case $options in
    d ) domain=$OPTARG;;
    r ) restart=1;;
    p ) print_service=1;;
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done

[ -z $domain ] && echo "You must specify the domain" && exit 1

is_systemd=1

[ "$(lsb_release -r -s)" = "14.04" ] && is_systemd=0
  

if [ "$is_systemd" -eq 0 ]; then
  service=`initctl list | egrep "\-$domain\s" | head -n 1 | cut -f1 -d" "`
else
  service=`systemctl list-unit-files | egrep "\-$domain.service" | head -n 1 | cut -f1 -d" "`
  service=`echo "${service//.service}"`
fi

[ -z $service ] && log 'Service not found' && exit

[ "$restart" -eq 1 ] && service $service restart && exit

[ "$print_service" -eq 1 ] && echo $service && exit

service $service status

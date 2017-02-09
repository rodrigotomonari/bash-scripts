#!/bin/bash

VHOST_DIR="/home/vhosts/"

SCRIPT=$(readlink -f "$0") 

BASEDIR=$(dirname $SCRIPT)


function print_usage()
{
    echo " -- Enable SSH KEY --"
    echo ""
    echo "Use: $0 [options] -d <domain> -u <user>"
    echo ""
    echo "Options:"
    echo "-c : check"
    echo "-s : subdomain"
    echo ""
    exit 1
}

while getopts "u:d:crh?" options; do
  case $options in
    u ) user=$OPTARG;;
    d ) domain=$OPTARG;;
    c ) check=1;;
    s ) subdomain=1;;
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;

  esac
done

[ -z $user ] && echo "You must specify the user" && exit 1
[ -z $domain ] && echo "You must specify the domain" && exit 1

if [ ! -d "${VHOST_DIR}${domain}/.ssh/" ] 
then
    mkdir ${VHOST_DIR}${domain}/.ssh/
    chmod 711 ${VHOST_DIR}${domain}/.ssh/
fi

if [ -e "${VHOST_DIR}${domain}/.ssh/authorized_keys" ]
then

    ret=`grep -c $user "${VHOST_DIR}${domain}/.ssh/authorized_keys"`

    if [ $ret -ge 1 ]
    then 
        echo "User already has ssh permission"
    else
        echo "Granted permission"
        cat ${BASEDIR}/keys/$user >> "${VHOST_DIR}${domain}/.ssh/authorized_keys"
    fi  
else 
    echo "Authorized_keys created and granted permission"
    cat ${BASEDIR}/keys/$user >> "${VHOST_DIR}${domain}/.ssh/authorized_keys"
    chmod 644 "${VHOST_DIR}${domain}/.ssh/authorized_keys"
fi

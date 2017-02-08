#!/bin/bash

VHOSTS_DIR="/home/vhosts"

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname $SCRIPT)

force=0
php_support=1


function print_usage()
{
        echo "-- Add vhost --"
        echo ""
        echo "Use: $0 [options] -d <domain>"
        echo ""
        echo "Options:"
	echo "-u : Use a custom user"
	echo "-p : No PHP support"
        echo "-f : Force files overwrite"
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
    f ) force=1;;
    p ) php_support=0;; 
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done

[ -z $domain ] && echo "You must specify the domain" && exit 1

[ -z $user ] && user=$domain

[ ${#user} -gt 32 ] && echo "Username length bigger than 32 chars. Use -u and specify a username"

log "Verify if user does not exist"

if [ -n  "$(getent passwd $user)" ]; then
	log "--- User already exist" 
else
	log "--- Creating user"
	useradd --home-dir ${VHOSTS_DIR}/$domain --shell /bin/bash --create-home $user
fi

log "--- Adding www-data to user group"
addgroup www-data $user > /dev/null

#log "--- Adding user do sftp group"
#addgroup $user sftp

log "Creating public diretory"
[ ! -d ${VHOSTS_DIR}/$domain/public ] && mkdir ${VHOSTS_DIR}/$domain/public

log "Allowing ssh users"
${BASEDIR}/allow-user.sh -d $domain -u rodrigo.tomonari
${BASEDIR}/allow-user.sh -d $domain -u diego.rocha

log "Setting permissions"

#Prevent user adding new keys
chown root:root ${VHOSTS_DIR}/$domain/.ssh

#Allow write access to public
chown $user:$user ${VHOSTS_DIR}/$domain/public
chmod 750 ${VHOSTS_DIR}/$domain/public

#Fix chroot permition
chown root:root ${VHOSTS_DIR}/$domain

log "Configuring vhosts"

if [ $php_support -eq 1 ]; then

	if [ $force -eq 1 -o ! -f /etc/apache2/sites-available/${domain}.conf ]; then
		sed "s/DOMAIN/$domain/g" ${BASEDIR}/add_vhosts_files/TEMPLATE_VHOSTS > /etc/apache2/sites-available/${domain}.conf 
	elif [ -f /etc/apache2/sites-available/${domain}.conf ]; then
		log "--- Vhosts file already exist. Use -f to overwrite"
	fi
	if [ $force -eq 1 -o ! -f /etc/php5/fpm/php5-fpm-${domain}.conf ]; then
		sed "s/DOMAIN/$domain/g" ${BASEDIR}/add_vhosts_files/FPM_TEMPLATE > /etc/php5/fpm/php5-fpm-${domain}.conf
		sed -i "s/USER/$user/g" /etc/php5/fpm/php5-fpm-${domain}.conf
	elif [ -f /etc/php5/fpm/php5-fpm-${domain}.conf ]; then
		log "--- PHP FPM Already exist. Use -f to overwrite"
	fi

	if [ $force -eq 1 -o ! -f /etc/init/php5-fpm-${domain}.conf ]; then
		sed "s/DOMAIN/$domain/g" ${BASEDIR}/add_vhosts_files/FPM_INIT_TEMPLATE > /etc/init/php5-fpm-${domain}.conf
	elif [ -f /etc/init/php5-fpm-${domain}.conf ]; then
		log "--- PHP FPM INIT Already exist. Use -f to overwrite"
	fi
else
	if [ $force -eq 1 -o ! -f /etc/apache2/sites-available/${domain}.conf ]; then
		sed "s/DOMAIN/$domain/g" ${BASEDIR}/add_vhosts_files/TEMPLATE_VHOSTS_NO_PHP > /etc/apache2/sites-available/${domain}.conf 
	elif [ -f /etc/apache2/sites-available/${domain}.conf ]; then
		log "--- Vhosts file already exist. Use -f to overwrite"
	fi

fi


log "Activating Vhost"
a2ensite $domain

log "Test apache2 config files"
apache2ctl configtest &> /dev/null
apache_test=$? 
if [ $apache_test -ne 0 ]; then
	log "*** ERROR Vhost Conf ***---"
fi

if [ $php_support -eq 1 ]; then
	log "Test FPM config files"
	fpm_test=$(/usr/sbin/php5-fpm --fpm-config /etc/php5/fpm/php5-fpm-${domain}.conf -t 2>&1 | grep "\[ERROR\]" || true);
	if [ -n "$fpm_test" ]; then
		log "*** ERROR IN FPM ***---"
	fi

	if [ $apache_test -eq 0  ] && [ -z "$fpm_test" ]; then
		echo ""
		echo "service apache2 reload && service php5-fpm-${domain} start"
	else
		echo ""
		log "*** VERIFY CONFIG ***---"
	fi
else
	if [ $apache_test -eq 0  ]; then
		echo ""
		echo "service apache2 reload"
	else
		echo ""
                log "*** VERIFY CONFIG ***---"
	fi
	
fi


exit 0

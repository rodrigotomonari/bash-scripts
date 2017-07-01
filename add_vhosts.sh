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
    echo "-a : PHP Version"
    echo ""
    exit 1
}

function log()
{
    echo "--- $1"
}

function replace_keys() {
    sed -i "s/DOMAIN/$domain/g" $1
    sed -i "s/USER/$user/g" $1
    sed -i "s/FPM_CONF/${fpm_conf_file//\//\\/}/g" $1
    sed -i "s/PHP_VERSION/${php_version}/g" $1
    sed -i "s/FPM_SOCKET/${fpm_socket//\//\\/}/g" $1
    sed -i "s/FPM_BIN/${fpm_bin//\//\\/}/g" $1
    sed -i "s/FPM_CHECKCONF/${fpm_checkconf//\//\\/}/g" $1
    sed -i "s/FPM_PID/${fpm_pid//\//\\/}/g" $1
}

while getopts "d:u:a:fph?" options; do
  case $options in
    d ) domain=$OPTARG;;
    u ) user=$OPTARG;;
    a ) php_version=$OPTARG;;
    f ) force=1;;
    p ) php_support=0;;
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done

[ -z $domain ] && echo "You must specify the domain" && exit 1

[ -z $php_version ] && echo "You must specify the PHP Version" && exit 1

[ -z $user ] && user=$domain

[ ${#user} -gt 32 ] && echo "Username length bigger than 32 chars. Use -u and specify a username"

[ ! -d ${VHOSTS_DIR} ] && mkdir -p ${VHOSTS_DIR}

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
chmod o-r ${VHOSTS_DIR}/$domain

log "Configuring vhosts"

vhost_file="/etc/apache2/sites-available/${domain}.conf"
fpm_socket="/var/run/php${php_version}-fpm-${domain}.sock"
init_file="/etc/init/php-fpm-${domain}.conf"
fpm_service="/lib/systemd/system/php-fpm-${domain}.service"
fpm_pid="/var/run/php${php_version}-fpm-${domain}.pid"

if [ "$(lsb_release -r -s)" = "14.04" ]; then
    fpm_conf_file="/etc/php5/fpm/php-fpm-${domain}.conf"
    fpm_bin="/usr/sbin/php5-fpm"
    fpm_checkconf="/usr/lib/php5/php-fpm-${domain}-checkconf"
else
    fpm_conf_file="/etc/php/${php_version}/fpm/php-fpm-${domain}.conf"
    fpm_bin="/usr/sbin/php-fpm${php_version}"
    fpm_checkconf="/usr/lib/php/php${php_version}-fpm-${domain}-checkconf"
fi

if [ $php_support -eq 1 ]; then
    if [ $force -eq 1 -o ! -f  $vhost_file ]; then
        cat ${BASEDIR}/add_vhosts_files/TEMPLATE_VHOSTS > $vhost_file
        replace_keys $vhost_file
    elif [ -f $vhost_file ]; then
        log "--- Vhosts file already exist. Use -f to overwrite"
    fi
    
    if [ $force -eq 1 -o ! -f $fpm_conf_file ]; then
        cat ${BASEDIR}/add_vhosts_files/FPM_TEMPLATE > $fpm_conf_file
        replace_keys $fpm_conf_file
    elif [ -f $fpm_conf_file ]; then
        log "--- PHP FPM Already exist. Use -f to overwrite"
    fi
    
    if [ $force -eq 1 -o ! -f $init_file ]; then
        cat ${BASEDIR}/add_vhosts_files/FPM_INIT_TEMPLATE > $init_file
        replace_keys $init_file
    elif [ -f $init_file ]; then
        log "--- PHP FPM INIT Already exist. Use -f to overwrite"
    fi

    if [ $force -eq 1 -o ! -f $fpm_checkconf ]; then
        cat ${BASEDIR}/add_vhosts_files/FPM_CHECKCONF_TEMPLATE > $fpm_checkconf
        replace_keys $fpm_checkconf
        chmod +x $fpm_checkconf
    elif [ -f $fpm_checkconf ]; then
        log "--- PHP FPM CHECKCONF Already exist. Use -f to overwrite"
    fi

    if [ $force -eq 1 -o ! -f $fpm_service ]; then
        cat ${BASEDIR}/add_vhosts_files/FPM_SERVICE_TEMPLATE > $fpm_service
        replace_keys $fpm_service
    elif [ -f $fpm_service ]; then
        log "--- PHP FPM SERVICE Already exist. Use -f to overwrite"
    fi

    # Create FPM Log
    touch /var/log/php-fpm-$domain.log
    chown $user:$user /var/log/php-fpm-$domain.log

else
    if [ $force -eq 1 -o ! -f $vhost_file ]; then
        cat ${BASEDIR}/add_vhosts_files/TEMPLATE_VHOSTS_NO_PHP > $vhost_file
        replace_keys $vhost_file
    elif [ -f $vhost_file ]; then
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
    
    $fpm_checkconf
    if [ $? -ne 0 ]; then
        log "*** ERROR IN FPM ***---"
    fi

    if [ $apache_test -eq 0  ] && [ -z "$fpm_test" ]; then
        echo ""

        if [ "$(lsb_release -r -s)" = "14.04" ]; then
            echo "service apache2 reload && service php-fpm-${domain} start"
        else
            echo "service apache2 reload && systemctl enable php-fpm-${domain} && service php-fpm-${domain} start"
        fi
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
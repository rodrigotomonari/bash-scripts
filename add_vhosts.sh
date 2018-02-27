#!/bin/bash

VHOSTS_DIR="/home/vhosts"

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname ${SCRIPT})

TEMPLATE_DIR=${BASEDIR}/add_vhosts_files

# Import functions
. ${BASEDIR}/utils/log.sh
. ${BASEDIR}/utils/domain.sh
. ${BASEDIR}/utils/compare.sh

force=0
php_support=1
compare=0
ask_confirmation=1

ubuntu_version=$(lsb_release -r -s)

function php_guess()
{
    # Use PHP 5 in Ubuntu 14.04
    [ "${ubuntu_version}" = "14.04" ] && php_version="5" && return 0

    php_version=$(ls /etc/php/ | tail -n 1)
}

function options_check()
{
    if [ -z "${domain}" ]
    then
        log_error "You must specify the domain"
        log_blank

        print_usage
        exit 1
    fi

    [ -z "${user}" ] && user=${domain}

    if [ ${#user} -gt 32 ]
    then
        log_error "Username length bigger than 32 chars. Use -u and specify a username"
        exit 1
    fi

    if [ -z "$php_version" ] && [ "${php_support}" -eq "1" ]
    then
        log_warn "No PHP version provided. Trying to guess"

        php_guess

        log "PHP ${php_version} selected"
    fi
}

function create_vhost_user()
{
    # Create vhost dir
    [ ! -d ${VHOSTS_DIR} ] && mkdir -p ${VHOSTS_DIR}

    log "Verify if user does not exist"
    if [ -n  "$(getent passwd ${user})" ]; then
        log_warn "- User already exist"
    else
        log "- Creating user"
        useradd --home-dir ${VHOSTS_DIR}/${domain} --shell /bin/bash --create-home ${user}
    fi

    log "Set user home permission"
    chown ${user}:${user} ${VHOSTS_DIR}/${domain}
    chmod 710 ${VHOSTS_DIR}/${domain}

    log "- Adding www-data to user group"
    addgroup www-data ${user} > /dev/null

    log "Creating public folder"
    [ ! -d ${VHOSTS_DIR}/${domain}/public ] && mkdir ${VHOSTS_DIR}/${domain}/public

    log "Allowing ssh users"
    # Default users
    ${BASEDIR}/allow-user.sh -d ${domain} -u rodrigo.tomonari
    ${BASEDIR}/allow-user.sh -d ${domain} -u diego.rocha
    ${BASEDIR}/allow-user.sh -d ${domain} -u leandro.polimeno 

    # Allow write access to public
    chown ${user}:${user} ${VHOSTS_DIR}/${domain}/public
    chmod 750 ${VHOSTS_DIR}/${domain}/public
}

function set_variables_file_path
{
    vhost_file="/etc/apache2/sites-available/${domain}.conf"
    vhost_fpm_conf="/etc/apache2/vhosts-conf-available/${domain}/fpm.conf"
    fpm_socket="/var/run/php${php_version}-fpm-${domain}.sock"
    init_file="/etc/init/php${php_version}-fpm-${domain}.conf"
    fpm_service="/lib/systemd/system/php${php_version}-fpm-${domain}.service"
    fpm_pid="/var/run/php${php_version}-fpm-${domain}.pid"
    fpm_conf_file="/etc/php/${php_version}/fpm/php${php_version}-fpm-${domain}.conf"
    fpm_bin="/usr/sbin/php-fpm${php_version}"
    fpm_checkconf="/usr/lib/php/php${php_version}-fpm-${domain}-checkconf"
    php_log="/var/log/php/php-fpm-${domain}.log"
    log_rotate="/etc/logrotate.d/php${php_version}-fpm-${domain}"
    php_reopenlogs="/usr/lib/php/php${php_version}-fpm-${domain}-reopenlogs"
    monit_conf="/etc/monit/conf.d/php${php_version}-fpm-${domain}"

    if [ "${ubuntu_version}" = "14.04" ]; then
        fpm_conf_file="/etc/php5/fpm/php${php_version}-fpm-${domain}.conf"
        fpm_bin="/usr/sbin/php5-fpm"
        fpm_checkconf="/usr/lib/php5/php${php_version}-fpm-${domain}-checkconf"
        php_reopenlogs="/usr/lib/php5/php-fpm-${domain}-reopenlogs"
    fi
}

function test_overwrite
{
    local file=$1

    if [ ${force} -eq 1 -o ${compare} -eq 1 -o ! -f ${file} ]
    then
        return 0
    else
        return 1
    fi
}

function create_vhost
{
    if $(test_overwrite ${vhost_file})
    then
        mkdir -p /etc/apache2/vhosts-conf-available/${domain}/

        create_tmp TEMPLATE_VHOST
        move_or_diff TEMPLATE_VHOST ${vhost_file}
    else
        log_warn "Vhosts file already exist. Use -f to overwrite"
    fi
}

function create_vhost_fpm_conf
{
    if $(test_overwrite ${vhost_fpm_conf})
    then
        create_tmp TEMPLATE_VHOST_FPM_CONF
        move_or_diff TEMPLATE_VHOST_FPM_CONF ${vhost_fpm_conf}
    else
        log_warn "VHOST FPM CONF Already exist. Use -f to overwrite"
    fi
}

function create_fpm_config
{
    if $(test_overwrite ${fpm_conf_file})
    then
        create_tmp FPM_TEMPLATE
        move_or_diff FPM_TEMPLATE ${fpm_conf_file}

        [ ! -d /var/log/php/ ] && mkdir /var/log/php/
        touch ${php_log}
        chown root:${user} ${php_log}
        chmod 660 ${php_log}
    else
        log_warn "PHP FPM Already exist. Use -f to overwrite"
    fi
}

function create_fpm_checkconf
{
    if $(test_overwrite ${fpm_checkconf})
    then
        create_tmp FPM_CHECKCONF_TEMPLATE
        move_or_diff FPM_CHECKCONF_TEMPLATE ${fpm_checkconf}

        [ -f ${fpm_checkconf} ] && chmod +x ${fpm_checkconf}
    else
        log_warn "PHP FPM CHECKCONF Already exist. Use -f to overwrite"
    fi
}

function create_fpm_init
{
    if $(test_overwrite ${init_file})
    then
        create_tmp FPM_INIT_TEMPLATE
        move_or_diff FPM_INIT_TEMPLATE ${init_file}
    else
        log_warn "PHP FPM INIT Already exist. Use -f to overwrite"
    fi
}

function create_fpm_service
{
    if $(test_overwrite ${fpm_service})
    then
        create_tmp FPM_SERVICE_TEMPLATE
        move_or_diff FPM_SERVICE_TEMPLATE ${fpm_service}
    else
        log_warn "PHP FPM SERVICE Already exist. Use -f to overwrite"
    fi
}

function create_log_rotate
{
    if $(test_overwrite ${log_rotate})
    then
        create_tmp TEMPLATE_LOGROTATE
        move_or_diff TEMPLATE_LOGROTATE ${log_rotate}

        [ -f ${log_rotate} ] && chown root:root ${log_rotate}
    else
        log_warn "LOG ROTATE CONF Already exist. Use -f to overwrite"
    fi

    if $(test_overwrite ${php_reopenlogs})
    then
        create_tmp TEMPLATE_FPM_REOPENLOGS
        move_or_diff TEMPLATE_FPM_REOPENLOGS ${php_reopenlogs}

        [ -f ${php_reopenlogs} ] && chmod +x ${php_reopenlogs}
    else
        log_warn "FPM REOPEN LOGS Already exist. Use -f to overwrite"
    fi
}

function create_monit
{
    log "Configuring monit"
    if $(test_overwrite ${monit_conf})
    then
        create_tmp TEMPLATE_MONIT
        move_or_diff TEMPLATE_MONIT ${monit_conf}

        if [ -f ${monit_conf} ]
        then
            monit reload 2> /dev/null
        fi
    else
        log_warn "MONIT CONF Already exist. Use -f to overwrite"
    fi
}

function create_tmp
{
    local template_name=$1

    cat ${TEMPLATE_DIR}/${template_name} > ${TEMPLATE_DIR}/tmp/${template_name}
    replace_keys ${TEMPLATE_DIR}/tmp/${template_name}
}

function move_or_diff
{
    local temp=${TEMPLATE_DIR}/tmp/$1
    local final=$2

    # Compare files
    if [ -f ${final} -a ${compare} -eq 1 ]
    then
        log_success "Comparing: ${final} ${temp}"
        compare ${final} ${temp}
        echo ""
    fi

    # Ask confirmation
    if [ -f ${final} -a ${ask_confirmation} -eq 1 ]
    then
        log_warn "Do you want to replace ${final}?"
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) mv ${temp} ${final}; break;;
                No ) break;;
            esac
        done
    else
        mv ${temp} ${final}
    fi
}

function check_all()
{
    log "Activating Vhost"
    a2ensite ${domain}

    log "Test apache2 config files"
    apache2ctl configtest &> /dev/null
    apache_test=$?
    if [ ${apache_test} -ne 0 ]
    then
        log_error "*** ERROR Vhost Conf ***---"
    fi

    if [ ${php_support} -eq 1 ]
    then
        log "Test FPM config files"

        ${fpm_checkconf}

        fpm_test=$?

        if [ ${fpm_test} -ne 0 ]
        then
            log_error "*** ERROR IN FPM ***---"
        else
            if [ "${ubuntu_version}" = "14.04" ]
            then
                log_success "service php${php_version}-fpm-${domain} start"
            else
                log_success "systemctl enable php${php_version}-fpm-${domain} && service php${php_version}-fpm-${domain} start"
            fi
        fi
    fi

    if [ ${apache_test} -eq 0  ]; then
        log_success "service apache2 reload"
    fi

    if [ -f ${monit_conf} ]
    then
        monit_test=$(monit -t 2> /dev/null)

        if [ "${fpm_test}" -eq 0  ]
        then
            log_success "monit monitor php${php_version}-fpm-${domain}"
        else
            log_error "*** ERROR Monit ***"
        fi
    fi
}

function print_usage()
{
    echo "-- Add vhost --"
    echo ""
    echo "Use: $0 [options] -d <domain>"
    echo ""
    echo "Options:"
    echo "-u : Use a custom user"
    echo "-c : Compare if already file exist"
    echo "-n : No PHP support"
    echo "-f : Force files overwrite"
    echo "-p : PHP Version"
    echo "-y : Do not ask confirmation for file replace"
    echo ""
    exit 1
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
    sed -i "s/PHP_LOG/${php_log//\//\\/}/g" $1
    sed -i "s/FPM_REOPENLOGS/${php_reopenlogs//\//\\/}/g" $1
}

while getopts "d:u:p:fncyh?" options; do
  case ${options} in
    d ) domain=$OPTARG;;
    u ) user=$OPTARG;;
    p ) php_version=$OPTARG;;
    f ) force=1;;
    n ) php_support=0;;
    c ) compare=1;;
    y ) ask_confirmation=0;;
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done

options_check

set_variables_file_path

if [ ${compare} -eq 0 -o ${force} -eq 1 ]
then
    create_vhost_user
fi

create_vhost

if [ ${php_support} -eq 1 ]
then
    create_vhost_fpm_conf

    create_fpm_config

    create_fpm_checkconf

    create_fpm_init

    create_fpm_service

    create_log_rotate

    create_monit
fi

if [ ${compare} -eq 0 -o ${force} -eq 1 ]
then
    check_all
fi

exit 0

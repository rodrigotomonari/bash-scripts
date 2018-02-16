#!/bin/bash

VHOSTS_DIR="/home/vhosts"

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname ${SCRIPT})

# Import functions
. ${BASEDIR}/utils/log.sh


# Permissions check
log_success "Checking domains permissions"
for domain in `ls ${VHOSTS_DIR}`
do
    [ ! -d ${VHOSTS_DIR}/${domain}/public ] && log_error "Public folder not found: ${VHOSTS_DIR}/${domain}/public" && continue

    user=$(stat -c '%U' ${VHOSTS_DIR}/${domain})
    perms=$(stat -c "%a" ${VHOSTS_DIR}/${domain})

    if [ "${user}" == "root" ]
    then
        [ "${perms}" != "711" ] && log_warn "Consider: chmod 711 ${VHOSTS_DIR}/${domain}"
    else
        [ "${perms}" != "710" ] && log_warn "Consider: chmod 710 ${VHOSTS_DIR}/${domain}"
    fi

    user=$(stat -c '%U' ${VHOSTS_DIR}/${domain}/public)
    perms=$(stat -c "%a" ${VHOSTS_DIR}/${domain/public})

    [ "${perms}" != "710" ] && log_warn "Consider: chmod 710 ${VHOSTS_DIR}/${domain}/public"

    # Check if www-data is in domain group
    if [ "$(getent group ${user} | grep -c "www-data")" -ne "1" ]
    then
        log_warn "Consider: adduser www-data ${user}"
    fi
done

# Wordpress install check


# Check root folder
log_success "Checking /root"
perms=$(stat -c "%a" /root)
[ "${perms}" != "700" ] && log "Changing root folder permission to 700" && chmod 700 /root

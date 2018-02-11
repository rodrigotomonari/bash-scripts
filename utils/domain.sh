#!/bin/bash

VHOST_DIR="/home/vhosts"

# Verify if the provided domain exist
function domain_exist?()
{
    local domain

    domain=$1

    [ ! -d "${VHOST_DIR}/${domain}" ] && return 1

    return 0
}

# Verify if the provided domain has an Apache vhost config file
function apache_vhost_exist?()
{
    local domain

    domain=$1

    [ ! -e "/etc/apache2/sites-available/${domain}.conf" ] && return 1

    return 0
}
#!/bin/bash

# Version 1
# License Type: GNU GENERAL PUBLIC LICENSE, Version 3
# Author:
# Rodrigo Tomonari Muino / https://github.com/rodrigotomonari
# Description:
# This script creates credentials file and configure environment variables

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname ${SCRIPT})

# Import functions
. ${BASEDIR}/utils/log.sh

function configure_mysql_credentials()
{
    log "Creating MySQL credentials file"

    while [[ -z "$mysql_user" ]]
    do
      read -p "MySQL username: " mysql_user
    done

    while [[ -z "$mysql_password" ]]
    do
      read -p "MySQL password: " mysql_password
    done

    cat > ~/.my.cnf << EndOfFile
[client]
user=${mysql_user}
password=${mysql_password}
EndOfFile

    chmod 600 ~/.my.cnf
}

configure_mysql_credentials

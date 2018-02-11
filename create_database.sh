#!/bin/bash

# Version 1
# License Type: GNU GENERAL PUBLIC LICENSE, Version 3
# Author:
# Rodrigo Tomonari Muino / https://github.com/rodrigotomonari
# Description:
# Create database and user in MySQL

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname ${SCRIPT})

# Import functions
. ${BASEDIR}/utils/log.sh

# Check parameters
function options_check()
{
    if [ -z "${database}" ]
    then
        log_error "You must specify the database name"
        log_blank

        print_usage
        exit 1
    fi

    if [ ${#database} -ge 64 ]
    then
        log_error "MySQL database name has to be up to 64 characters long. Current length: ${#database}"
        log_blank

        print_usage
        exit 1
    fi

    if [ -z "${user}" ]
    then
        log_error "You must specify the username name"
        log_blank

        print_usage
        exit 1
    fi

    if [ ${#user} -ge 16 ]
    then
        log_error "MySQL username has to be up to 16 characters long. Current length: ${#user}"
        log_blank

        print_usage
        exit 1
    fi

    if [ -z "${password}" ]
    then
        log_warn "Generating a password"
        password=$(date +%s | sha256sum | base64 | head -c 20)
        log_success "Password: ${password}"
    fi
}

function main()
{
    count=$(echo "SELECT COUNT(*) FROM mysql.user WHERE user = '${user}';" | mysql --skip-column-names)
    if [ "${count}" -eq "0" ]
    then
        log "Creating user"
        echo "CREATE USER '${user}'@'localhost' IDENTIFIED BY '${password}';" | mysql
    else
        log_warn "User ${user} already exist!"
    fi

    count=$(echo "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${database}';" | mysql --skip-column-names | wc -l)
    if [ "${count}" -eq "0" ]
    then
        log "Creating database"
        echo "CREATE DATABASE ${database} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" | mysql
    else
        log_warn "Database ${database} already exist!"
    fi

    log "Granting permissions to database"
    echo "GRANT ALL PRIVILEGES ON ${database}.* TO '${user}'@'localhost';" | mysql


    log "Test connection"
    mysql -u${user} -p${password} ${database} -e"show databases";
}

function print_usage()
{
    echo "-- Disable SSH KEY --"
    echo ""
    echo "Use: $0 -b <database> -u <user>"
    echo ""
    echo "Options:"
    echo "-b : Database"
    echo "-u : User"
    echo "-p : Password"
    echo ""
    exit 1
}

while getopts "u:b:p:h?" options; do
    case ${options} in
        u ) user=$OPTARG;;
        b ) database=$OPTARG;;
        p ) password=$OPTARG;;
        h ) print_usage;;
        \? ) print_usage;;
        * ) print_usage;;
    esac
done

options_check

main

#!/bin/bash

# Version 2
# License Type: GNU GENERAL PUBLIC LICENSE, Version 3
# Author:
# Rodrigo Tomonari Muino / https://github.com/rodrigotomonari
# Description:
# Dump Mysql database

SCRIPT=$(readlink -f "$0")

BASEDIR=$(dirname ${SCRIPT})

# Import functions
. ${BASEDIR}/utils/log.sh

# Check parameters
function options_check()
{
    if [ -n "${database}" ]
    then
        log "Checking if database ${database} exist"
        database_exist? ${database}
        if [ "$?" -ne "0" ]
        then
            log_error "Database ${database} does not exist"
            exit 1
        fi
    fi

    if [ -n "${output}" ]
    then
        log "Checking if output dir ${output} exist"

        if [ ! -d ${output} ]
        then
            log_error "Output dir ${output} does not exist"
            exit 1
        fi
    fi
}

function database_exist?()
{
    count=$(echo "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${database}';" | mysql --skip-column-names | wc -l)

    if [ "${count}" -eq 1 ]
    then
        return 0
    else
        return 1
    fi
}

function dump()
{
    local database=$1

    log "Dumping ${database}"

    mysqldump --add-drop-table --lock-tables=false --skip-extended-insert --events ${database} | bzip2 -c > "${database}.sql.bz2"
}

function export_all()
{
    log "Exporting all"
    while read database
    do
        dump ${database}
    done < <(mysql --skip-column-names --silent -e "SHOW DATABASES" | grep -v performance_schema | grep -v information_schema)
}

function main()
{
    [ -n "${output}" ] && cd ${output}

    if [ -z "${database}" ]
    then
        export_all
    else
        dump ${database}
    fi

    [ -n "${output}"  ] && cd -
}

function print_usage()
{
    echo "-- Dump Mysql --"
    echo ""
    echo "Use: $0 [options]"
    echo ""
    echo "Options:"
    echo "-b : Database"
    echo "-o : Save dir"
    echo ""
    exit 1
}

while getopts "b:o:h?" options; do
  case ${options} in
    b ) database=$OPTARG;;
    o ) output=$OPTARG;;
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done

options_check

main

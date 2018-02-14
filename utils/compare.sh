#!/usr/bin/env bash

function compare
{
    local old_file=$1
    local new_file=$2

    diff -s ${old_file} ${new_file} > /dev/null
    if [ $? -eq 0 ]; then
        echo "The files are identical"
    else
        diff -y --suppress-common-lines -W $(( $(tput cols) - 2 )) ${old_file} ${new_file}
    fi
}
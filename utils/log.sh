#!/bin/bash

LOG_COLOR_RESET="$(tput setaf 7)"
LOG_COLOR_RED="$(tput setaf 1)"
LOG_COLOR_GREEN="$(tput setaf 2)"
LOG_COLOR_YELLOW="$(tput setaf 3)"

function log()
{
    echo $LOG_COLOR_RESET$1
}

function log_success()
{
    echo $LOG_COLOR_GREEN$1
    echo -n $LOG_COLOR_RESET
}

function log_error()
{
    echo $LOG_COLOR_RED$1
    echo -n $LOG_COLOR_RESET
}

function log_warn()
{
    echo $LOG_COLOR_YELLOW$1
    echo -n $LOG_COLOR_RESET
}

function log_blank()
{
    echo $LOG_COLOR_RESET
}

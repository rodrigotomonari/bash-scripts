#!/bin/bash

is_systemd=1

[ "$(lsb_release -r -s)" = "14.04" ] && is_systemd=0

if [ "$is_systemd" -eq 0 ]; then
  while read service; do
    service $service restart
  done < <(initctl list | grep php | grep fpm | cut -d" " -f1)
else
  while read service; do
    service $service restart
  done < <(systemctl list-unit-files | grep php | grep fpm | cut -d" " -f1 | sed -e 's/\.service$//')
fi

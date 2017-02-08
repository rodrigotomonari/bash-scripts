#!/bin/bash

 for x in `ls /etc/init/php5-fpm*`; do service `echo $x | cut -d'/' -f4 | sed 's/.conf//'` restart; done

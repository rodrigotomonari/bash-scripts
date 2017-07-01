#!/bin/bash

# Errors
# - configure: error: Your system does not support systemd.
# RUN: ln -s /lib/x86_64-linux-gnu/libsystemd-daemon.so.0 /lib/x86_64-linux-gnu/libsystemd-daemon.so 
#

function print_usage()
{
    echo "-- Install PHP --"
    echo ""
    echo "Use: $0 [options] -b <base_version> -v <version>"
    echo ""
    echo "Options:"
    echo "-b : Base Version (ie: 5.6, 7.0)"
    echo "-v : Version (ie: 5.6.30, 7.0.0)"
    echo ""
    exit 1
}

while getopts "b:v:h?" options; do
  case $options in
    b ) base_version=$OPTARG;;
    v ) php_version=$OPTARG;;
    h ) print_usage;;
    \? ) print_usage;;
    * ) print_usage;;
  esac
done


[ -z $base_version ] && echo "You must specify the base version" && exit 1

[ -z $php_version ] && echo "You must specify the PHP Version" && exit 1


[ ! -d /root/compiled_php ] && mkdir "/root/compiled_php" 

cd /root/compiled_php

if [ ! -f php-${php_version}.tar.bz2 ]; then
	wget http://de.php.net/get/php-${php_version}.tar.bz2/from/this/mirror -O php-${php_version}.tar.bz2
fi
	
tar jxf php-${php_version}.tar.bz2

cd php-${php_version}/

apt-get install build-essential libxml2-dev libssl-dev libbz2-dev libmcrypt-dev libmhash-dev libmysqlclient-dev libcurl4-openssl-dev libjpeg62-dbg libjpeg-dev libpng12-dev libfreetype6-dev libxslt1-dev libsystemd-dev

./configure \
--prefix=/opt/php-${php_version} \
--with-zlib-dir \
--with-freetype-dir \
--enable-mbstring \
--with-libxml-dir=/usr \
--enable-soap \
--enable-calendar \
--with-curl \
--with-mcrypt \
--with-zlib \
--with-gd \
--disable-rpath \
--enable-inline-optimization \
--with-bz2 \
--with-zlib \
--enable-sockets \
--enable-sysvsem \
--enable-sysvshm \
--enable-pcntl \
--enable-mbregex \
--enable-exif \
--enable-bcmath \
--with-mhash \
--enable-zip \
--with-pcre-regex \
--with-mysql \
--with-pdo-mysql \
--with-mysqli \
--with-jpeg-dir=/usr \
--with-png-dir=/usr \
--enable-gd-native-ttf \
--with-openssl \
--with-fpm-user=www-data \
--with-fpm-group=www-data \
--with-fpm-systemd \
--with-libdir=/lib/x86_64-linux-gnu \
--enable-ftp \
--with-gettext \
--with-xmlrpc \
--with-xsl \
--with-kerberos \
--enable-fpm

make



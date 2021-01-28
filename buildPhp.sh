#!/bin/bash

WORKDIR=$HOME/work
mkdir -p $WORKDIR
cd $WORKDIR
wget https://www.php.net/distributions/php-7.4.14.tar.gz
tar zxvf $WORKDIR/php-7.4.14.tar.gz
cd $WORKDIR/php-7.4.14

ONIG_CFLAGS=-I/usr/local/include ONIG_LIBS='-L/usr/local/lib -lonig' ./configure \
  --prefix=/usr/local/webserver/php \
  --sysconfdir=/usr/local/webserver/php/etc \
  --with-config-file-path=/usr/local/webserver/php/etc \
  --with-config-file-scan-dir=/usr/local/webserver/php/etc/php.d \
  --localstatedir=/usr/local/webserver/php/var \
  --datadir=/usr/local/webserver/php/share/php \
  --mandir=/usr/local/webserver/php/share/man \
  --enable-fpm --with-fpm-user=apache --with-fpm-group=apache \
  --with-zlib --enable-bcmath --enable-pcntl=shared --with-zip=shared --enable-intl=shared --with-bz2 --enable-ftp \
  --with-gettext --enable-mbstring --with-readline --with-curl \
  --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-mysqli \
  --with-openssl --without-sqlite3 --without-pdo-sqlite \
  --with-pear --enable-gd --enable-static

make clean
make INSTALL_ROOT=$WORKDIR/build/php-7.4.14 install

# extensions
# gearman

# https://github.com/wcgallego/pecl-gearman
# 有提到
# Note: This repo is no longer under active development beyond v2.0.6 (for PHP 7.3.x). If you're looking for a pecl-gearman repo with future updates (for PHP 7.4.x and beyond), you can find it at the official pecl-gearman repo here: https://github.com/php/pecl-networking-gearman

################################
# 非官方
################################
WORKDIR=$HOME/work
cd $WORKDIR
wget https://github.com/wcgallego/pecl-gearman/archive/master.zip
unzip master.zip 
cd $WORKDIR/pecl-gearman-master
$WORKDIR/build/php-7.4.14/usr/local/webserver/php/bin/phpize
./configure --with-php-config=$WORKDIR/build/php-7.4.14/usr/local/webserver/php/bin/php-config --with-gearman=/usr/local/webserver/gearmand
make clean
make INSTALL_ROOT=$WORKDIR/build/php-7.4.14 install

################################
# 官方
################################
WORKDIR=$HOME/work
cd $WORKDIR
wget https://pecl.php.net/get/gearman-2.1.0.tgz
cd $WORKDIR/gearman-2.1.0
$WORKDIR/build/php-7.4.14/usr/local/webserver/php/bin/phpize
./configure --with-php-config=$WORKDIR/build/php-7.4.14/usr/local/webserver/php/bin/php-config --with-gearman=/usr/local/webserver/gearmand
make clean
make INSTALL_ROOT=$WORKDIR/build/php-7.4.14 install

# memcached
WORKDIR=$HOME/work
cd $WORKDIR
wget https://pecl.php.net/get/memcached-3.1.5.tgz
tar zxvf memcached-3.1.5.tgz 
cd $WORKDIR/memcached-3.1.5
$WORKDIR/build/php-7.4.14/usr/local/webserver/php/bin/phpize
./configure --with-php-config=$WORKDIR/build/php-7.4.14/usr/local/webserver/php/bin/php-config --enable-static \
  --with-libmemcached-dir=/usr/local/webserver/libmemcached --disable-memcached-sasl
make clean
make INSTALL_ROOT=$WORKDIR/build/php-7.4.14 install

# memcache
WORKDIR=$HOME/work
cd $WORKDIR
wget https://pecl.php.net/get/memcache-4.0.5.2.tgz
tar zxvf memcache-4.0.5.2.tgz
cd $WORKDIR/memcache-4.0.5.2
/root/work/build/php-7.4.14/usr/local/webserver/php/bin/phpize
./configure --with-php-config=$WORKDIR/build/php-7.4.14/usr/local/webserver/php/bin/php-config --enable-static
make clean
make INSTALL_ROOT=/root/work/build/php-7.4.14 install

# redis
WORKDIR=$HOME/work
cd $WORKDIR
wget https://pecl.php.net/get/redis-5.3.2.tgz
tar zxvf redis-5.3.2.tgz 
cd $WORKDIR/redis-5.3.2
/root/work/build/php-7.4.14/usr/local/webserver/php/bin/phpize
./configure --with-php-config=/root/work/build/php-7.4.14/usr/local/webserver/php/bin/php-config --enable-static
make clean
make INSTALL_ROOT=/root/work/build/php-7.4.14 install

# mongodb
WORKDIR=$HOME/work
cd $WORKDIR
wget https://pecl.php.net/get/mongodb-1.9.0.tgz
cd $WORKDIR/mongodb-1.9.0
/root/work/build/php-7.4.14/usr/local/webserver/php/bin/phpize
./configure --with-php-config=/root/work/build/php-7.4.14/usr/local/webserver/php/bin/php-config --enable-static
make clean
make INSTALL_ROOT=/root/work/build/php-7.4.14 install


### Nginx+PHP+Percona編譯流程 ###
### wget -q https://raw.githubusercontent.com/joetww/work_script/master/install_Ngnix_PHP_Percona.sh -O - | bash
#版本：
#        nginx-1.13.4(編譯參數待確認)
#        openresty-1.13.6.2(考慮一起裝)
#        luarocks(給openresty用)
#        https://github.com/GUI/lua-resty-auto-ssl(搭配luarocks)
#        https://idoseek.com/1774(geoiplite2)
#        ruby-2.4.1(passenger所需)(這版本不打算裝)
#        openssl 1.0.2p(給nginx用)
#        rubygems-2.6.12(這版本不打算裝)
#        naxsi-0.55.3(這版本不打算裝)
#        passenger-5.1.5(這版本不打算裝)
#        libmcrypt-2.5.8(mysql & php所需)(yum就有了，所以不自己編譯了)/改用yum安裝
#        libmemcached-1.0.18/改用yum安裝
#        gearman-1.1.18
#        boost_1.59.0(gearman所需)(待確認，因為percona 反而不需要這麼高的版本)/改用yum安裝
#        postgresql-9.6.4(僅提供php & gearman的postgresql能力)(這版本不打算裝)
#        percona-server-5.7.19-17(mysql)/不用喔，換回原本的mysql
#        php 7.0.23
#        php-memcache-2.2.7
#        php-memcached-2.2.0
#        php-gearman-1.1.2
#        re2c 0.16(提供較好的configure能力)/改用yum安裝
#        redis 4.0.1
#注意：
#        WORKHOME & NAXSI_PATH & PHP_VERSION & PHP_PATH 使用時別忘記要確認
#秘訣：
#        sudo 可以設定延長session timeout
#        sudo visudo
#        修改 Defaults        env_reset,timestamp_timeout=30

#先說好，我不習慣直接用root做事情，所以會先用一個一般帳號處理大多數要處理的事情
#有需要時候再用sudo進行提昇權限的動作，
#所以先確認有一個一般帳號並且已經可以使用sudo。
#############################################
#正片開始
#先準備 
#############################################
DESTDIR=/www/`date +%Y%m%d`
sudo yum -y install epel-release
sudo yum -y groupinstall "Development tools"
sudo yum -y install wget zlib-devel curl-devel pcre-devel \
readline-devel libxml2-devel libjpeg-turbo-devel libpng-devel bzip2-libs bzip2-devel \
freetype-devel openldap-devel cmake expect gperf libuuid-devel \
glibc-static gdbm-devel libmaxminddb-devel \
boost-devel re2c GeoIP-devel 


#sudo yum -y install wget zlib-devel openssl-devel curl-devel pcre-devel \
#readline-devel libxml2-devel libjpeg-turbo-devel libpng-devel bzip2 bzip2-libs bzip2-devel \
#freetype-devel openldap-devel cmake expect gperf libevent-devel libuuid-devel \
#glibc-static gdbm-devel libmaxminddb libmaxminddb-devel libmcrypt-devel libmcrypt \
#boost boost-devel re2c GeoIP-devel libmemcached-devel 

#############################################
function addString {
        test -f $1 && 
        (
        grep -Fxq $2 $1 || sudo bash -c "cat >> $1" <<EOD
$(date "+### Add By $(whoami) at %Y-%m-%d %H:%M:%S ###")
$2
EOD
        ) || (
        sudo bash -c "cat >> $1" <<EOD
$(date "+###Add By $(whoami) at %Y-%m-%d %H:%M:%S ###")
$2
EOD
)
}

function makeEnv {
        WORKHOME=~/work/
        
        PROJOECT="B2B"
        NGINX_SOURCE=`find ${WORKHOME} -maxdepth 1 -type d -name "nginx*" | sort -V | tail -n 1`
        test -z ${PHP_VERSION+x} && echo "SET PHP_VERSION" && \
        PHP_VERSION=`curl -s http://php.net/downloads.php | \
        grep -P '<h3 id="v7\.0\.\d+" class="title">' | \
        sed -n 's/.*\(7.0.[0-9]\+\).*/\1/p'`
        PHP_PATH=/usr/local/webserver/php`echo $PHP_VERSION | sed 's/\./_/g'`
		OPENSSL_VERSION=`find $WORKHOME -type d -name "openssl*" -print | grep -Po 'openssl-\d+\.\d+\.\d+\w' | sort -u -V -r | head -n 1`
        sudo mkdir -p $WORKHOME
        sudo mkdir -p $DESTDIR
        
        CUSTOM_PATH="/usr/local/webserver/ruby/bin $PHP_PATH/bin /usr/local/webserver/mysql/bin /usr/local/webserver/pgsql/bin"
        for i in $CUSTOM_PATH;
        do
                test -d $i && \
                [[ ":$PATH:" != *":$i:"* ]] && PATH="$i:${PATH}"
        done

        addString /etc/ld.so.conf.d/local.conf "/usr/local/lib"
        addString /etc/ld.so.conf.d/local.conf "/usr/local/webserver/mysql/lib"
        addString /etc/ld.so.conf.d/local.conf "/usr/local/webserver/gearmand/lib"
        sudo ldconfig
}

#############################################
#安裝re2c
#makeEnv
#cd $WORKHOME 
#wget --no-check-certificate -N https://github.com/skvadrik/re2c/releases/download/0.16/re2c-0.16.tar.gz
#tar zxvf re2c-0.16.tar.gz && \
#cd re2c-0.16 && \
#./configure && \
#make && \
#sudo make install clean

##############################################
##安裝libmcrypt 2.5.8
makeEnv
cd $WORKHOME 
wget --no-check-certificate -N https://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
tar zxvf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure --prefix=/usr/local && \
make && sudo make install clean

#############################################
#安裝libmemcached-1.0.18
makeEnv
cd $WORKHOME
wget --no-check-certificate -N https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz
tar zxvf libmemcached-1.0.18.tar.gz
cd libmemcached-1.0.18 && \
./configure --prefix=/usr/local && \
make && sudo make DESTDIR=${DESTDIR} install && sudo make install clean

makeEnv
cd $WORKHOME
wget --no-check-certificate -N https://github.com/libevent/libevent/archive/release-1.4.15-stable.tar.gz
tar zxvf release-1.4.15-stable.tar.gz
cd libevent-release-1.4.15-stable
./configure --prefix=/usr/local && \
make && sudo make DESTDIR=${DESTDIR} install && sudo make install clean

##############################################
#安裝openssl 1.0.2p(給nginx用)
makeEnv
cd $WORKHOME 
wget --no-check-certificate -N https://www.openssl.org/source/openssl-1.1.0j.tar.gz && \
tar zxvf openssl-1.1.0j.tar.gz && \
cd openssl-1.1.0j && \
./config --prefix=/usr/local --openssldir=/usr/local/openssl && make 



#############################################
#makeEnv
#cd $WORKHOME
#
#wget --no-check-certificate -N https://jaist.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz && \
#tar zxvf boost_1_59_0.tar.gz && \
#cd boost_1_59_0 && \
#./bootstrap.sh
#sudo ./b2 --prefix=/usr/local install

##############################################
##安裝libpg
#makeEnv
#cd $WORKHOME
#wget --no-check-certificate -N https://ftp.postgresql.org/pub/source/v9.6.4/postgresql-9.6.4.tar.gz
#tar zxvf postgresql-9.6.4.tar.gz
#cd postgresql-9.6.4 && \
#./configure --prefix=/usr/local/webserver/pgsql && \
#make && sudo make INSTALL_ROOT=$DESTDIR install && sudo make install clean

#############################################
#安裝mysql(其實是安裝其分支 percona)
makeEnv
cd $WORKHOME
wget --no-check-certificate -N https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.24.tar.gz
tar zxvf mysql-5.7.24.tar.gz
cd mysql-5.7.24
mkdir -p bld && cd bld/ && \
sudo cmake -DCMAKE_INSTALL_PREFIX=/usr/local/webserver/mysql -DDEFAULT_CHARSET=utf8 \
         -DINSTALL_MYSQLTESTDIR= \
         -DDEFAULT_COLLATION=utf8_general_ci \
         -DDOWNLOAD_BOOST=1 \
         -DWITH_BOOST=/usr/local .. && \
sudo make && sudo make DESTDIR=$DESTDIR install && sudo make install clean

#############################################
#安裝mysql(其實是安裝其分支 percona)
#makeEnv
#cd $WORKHOME
#wget --no-check-certificate -N https://www.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.19-17/source/tarball/percona-server-5.7.19-17.tar.gz
#tar zxvf percona-server-5.7.19-17.tar.gz
#cd percona-server-5.7.19-17
#mkdir -p bld && cd bld/ && \
#sudo cmake -DCMAKE_INSTALL_PREFIX=/usr/local/webserver/mysql -DDEFAULT_CHARSET=utf8 \
#         -DINSTALL_MYSQLTESTDIR= \
#         -DDEFAULT_COLLATION=utf8_general_ci \
#         -DDOWNLOAD_BOOST=1 \
#         -DWITH_BOOST=/usr/local .. && \
#sudo make && sudo make INSTALL_ROOT=$DESTDIR install && sudo make install clean


##############################################
##安裝boost
#makeEnv
#cd $WORKHOME
#wget --no-check-certificate -N https://dl.bintray.com/boostorg/release/1.65.0/source/boost_1_65_0.tar.gz
#tar zxvf boost_1_65_0.tar.gz
#cd boost_1_65_0 && \
#./bootstrap.sh
#./b2
#sudo ./b2 --prefix=$DESTDIR/usr/local install

##############################################
##編譯ruby 2.4.1
#makeEnv
#cd $WORKHOME
#wget --no-check-certificate -N https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.1.tar.gz
#tar zxvf ruby-2.4.1.tar.gz
#cd ruby-2.4.1
#./configure --prefix=/usr/local/webserver/ruby && \
#make && sudo make install clean

##############################################
##安裝rubygems
#makeEnv
#cd $WORKHOME
#wget --no-check-certificate -N https://rubygems.org/rubygems/rubygems-2.6.12.tgz
#tar zxvf rubygems-2.6.12.tgz
#cd rubygems-2.6.12
#sudo "PATH=$PATH" $DESTDIR/usr/local/webserver/ruby/bin/ruby setup.rb
#sudo "PATH=$PATH" /usr/local/webserver/ruby/bin/ruby setup.rb




#############################################
#先抓好nginx source code
makeEnv
cd $WORKHOME
git clone --recursive https://github.com/leev/ngx_http_geoip2_module
git clone --recursive https://github.com/FRiCKLE/ngx_cache_purge
wget --no-check-certificate -N https://nginx.org/download/nginx-1.14.2.tar.gz
tar zxvf `find ${WORKHOME} -maxdepth 1 -type f -name "nginx*" | sort -V | tail -n 1`
NGINX_SOURCE=`find ${WORKHOME} -maxdepth 1 -type d -name "nginx*" | sort -V | tail -n 1`
cd $NGINX_SOURCE
#nginx的編譯設定要補
./configure --prefix=/usr/local/webserver/nginx \
        --with-http_geoip_module=dynamic \
        --with-http_ssl_module \
        --with-cc-opt=-Wno-error \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_auth_request_module \
        --http-client-body-temp-path=/usr/local/webserver/nginx/client_temp \
        --http-proxy-temp-path=/usr/local/webserver/nginx/proxy_temp \
        --http-fastcgi-temp-path=/usr/local/webserver/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/usr/local/webserver/nginx/uwsgi_temp \
        --http-scgi-temp-path=/usr/local/webserver/nginx/scgi_temp \
        --modules-path=/usr/local/webserver/nginx/modules \
        --with-stream_realip_module \
        --with-stream_geoip_module \
        --with-openssl=$WORKHOME/$OPENSSL_VERSION \
        --with-file-aio  \
        --with-http_sub_module \
        --with-http_gzip_static_module --with-http_stub_status_module \
		--add-module=$WORKHOME/ngx_cache_purge \
        --add-module=$WORKHOME/ngx_http_geoip2_module && \
gmake && sudo gmake DESTDIR=$DESTDIR install && sudo gmake install clean

cd $WORKHOME
wget --no-check-certificate -N https://openresty.org/download/openresty-1.13.6.2.tar.gz && \
tar zxvf openresty-1.13.6.2.tar.gz && \
cd openresty-1.13.6.2 && \
./configure --prefix=/usr/local/webserver/openresty --with-cc-opt=-O2 \
        --with-http_geoip_module --with-http_realip_module \
        --with-openssl=$WORKHOME/$OPENSSL_VERSION \
        --with-file-aio  --with-http_sub_module --with-http_gzip_static_module \
		--with-http_auth_request_module --with-http_v2_module \
        --http-client-body-temp-path=/usr/local/webserver/nginx/client_temp \
        --http-proxy-temp-path=/usr/local/webserver/nginx/proxy_temp \
        --http-fastcgi-temp-path=/usr/local/webserver/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/usr/local/webserver/nginx/uwsgi_temp \
        --http-scgi-temp-path=/usr/local/webserver/nginx/scgi_temp \
        --modules-path=/usr/local/webserver/nginx/modules \
		--add-module=$WORKHOME/ngx_cache_purge \
        --with-http_stub_status_module --add-module=$WORKHOME/ngx_http_geoip2_module && \
gmake && sudo gmake DESTDIR=$DESTDIR install && sudo gmake install clean

##############################################
##這裡先跳去準備安裝passenger，等一下會順便裝好nginx
#makeEnv
#cd $WORKHOME #其實不在乎在哪裡執行，只是一致一些
##安裝passenger
#makeEnv
#sudo "PATH=$PATH" /usr/local/webserver/ruby/bin/gem install passenger --no-rdoc --no-ri
##############################################
##用passenger-install-nginx-modul安裝nginx & nginx module
#makeEnv
#sudo "PATH=$PATH" \
#/usr/local/webserver/ruby/bin/passenger-install-nginx-module \
#--prefix=/usr/local/webserver/nginx \
#--nginx-source-dir=$NGINX_SOURCE \
#--languages ruby,python,nodejs \
#--auto

#漫長的等待......

#檢查安裝正確不正確
#makeEnv
#sudo "PATH=$PATH" /usr/local/webserver/ruby/bin/passenger-config validate-install

#若要使用passenger，則nginx.conf必須加入以下設定
#       http {
#               ...
#               passenger_root /usr/local/webserver/ruby/lib/ruby/gems/2.4.0/gems/passenger-5.1.5;
#               passenger_ruby /usr/local/webserver/ruby/bin/ruby;
#               ...
#       }



##############################################
##追加naxsi
#makeEnv
#cd $WORKHOME && \
#wget --no-check-certificate -N https://github.com/nbs-system/naxsi/archive/0.55.3.tar.gz
#tar zxvf 0.55.3.tar.gz && \
#cd naxsi-0.55.3 && \
#NAXSI_PATH=`pwd` && \
#cd $NGINX_SOURCE && \
##若是之前是用passenger編譯出來的，裡面部份檔案權限會是root，記得修改
#test `stat -c %U Makefile` == "root" && \
#sudo chown -R `stat -c "%U:%G" README` ./

##以下兩種編譯：把naxsi做成靜態模組嵌入nginx內，或是做成動態模組待設定載入
##這是靜態模組
#CONFIG_ARG=`/usr/local/webserver/nginx/sbin/nginx -V 2>&1 | \
#grep 'configure arguments:' | \
#sed -r 's/--add(-dynamic){0,1}-module=[^ ]*\/naxsi-[^ ]*\/naxsi_src//g' | \
#cut -d : -f 2-`
#./configure --add-module=$NAXSI_PATH/naxsi_src $CONFIG_ARG
##這是動態模組
##./configure --add-dynamic-module=$NAXSI_PATH/naxsi_src $CONFIG_ARG
##sudo make && sudo make INSTALL_ROOT=$DESTDIR install && sudo make install clean

##############################################
##若是以後想要單獨編譯動態模組
##重新跑一次configure，因為make clean會把Makefile清除
##makeEnv
##make modules && sudo make INSTALL_ROOT=$DESTDIR install && sudo make install clean

##nginx.conf 內 載入 modules的方法
##load_module modules/ngx_http_naxsi_module.so;

makeEnv
cd $WORKHOME
wget --no-check-certificate -N http://www.memcached.org/files/memcached-1.5.12.tar.gz 
tar zxvf memcached-1.5.12.tar.gz
cd memcached-1.5.12
./configure --prefix=/usr/local/webserver/memcached && \
make && \
sudo make DESTDIR=$DESTDIR install && sudo make install clean

#############################################
#安裝PHP 7.0.x
makeEnv
cd $WORKHOME && \
(
        wget http://tw1.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror \
                -O php-$PHP_VERSION.tar.gz --timeout=3 -t 1 || \
        wget http://us2.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror \
                -O php-$PHP_VERSION.tar.gz --timeout=3 -t 1 || \
        wget http://sg2.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror \
                -O php-$PHP_VERSION.tar.gz --timeout=3 -t 1
)
tar zxvf php-$PHP_VERSION.tar.gz && \
cd php-$PHP_VERSION && \
./configure \
--prefix=/usr/local/webserver/php \
--sysconfdir=/usr/local/webserver/php/etc \
--with-config-file-path=/usr/local/webserver/php/etc \
--with-config-file-scan-dir=/usr/local/webserver/php/etc/php.d \
--localstatedir=/usr/local/webserver/php/var \
--datadir=/usr/local/webserver/php/share/php \
--mandir=/usr/local/webserver/php/share/man \
--with-mysql=mysqlnd --with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd --with-iconv --with-freetype-dir \
--with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr \
--enable-xml --disable-rpath --enable-bcmath --with-gettext \
--enable-calendar --enable-dba=shared --with-gdbm --enable-ftp --with-readline \
--enable-shmop --enable-sysvsem --enable-inline-optimization \
--with-curl --enable-mbregex --enable-fpm --with-fpm-user=apache --with-fpm-group=apache \
--enable-mbstring --with-mcrypt  --with-gd --enable-gd-native-ttf \
--with-openssl --with-mhash --enable-pcntl --enable-sockets \
--with-ldap --with-libdir=lib64 --with-ldap-sasl --with-xmlrpc \
--enable-zip --with-bz2 --enable-soap && \
sudo make && sudo make INSTALL_ROOT=$DESTDIR install && \
sudo make install && \
sudo make clean

#############################################
#假如不存在php.ini的話
#先弄個預設的
makeEnv
test \! -f /usr/local/webserver/php/etc/php.ini && \
sudo cp $WORKHOME/php-$PHP_VERSION/php.ini-production \
/usr/local/webserver/php/etc/php.ini

test \! -f $DESTDIR/usr/local/webserver/php/etc/php.ini && \
sudo cp $WORKHOME/php-$PHP_VERSION/php.ini-production \
$DESTDIR/usr/local/webserver/php/etc/php.ini

#/usr/local/webserver/php/bin/pear version || (
##安裝pear
#makeEnv
#cd $WORKHOME/ && \
#wget --no-check-certificate -N http://pear.php.net/go-pear.phar
#sudo expect << EOD
#spawn /usr/local/webserver/php/bin/php go-pear.phar
#expect "or Enter to continue:"
#send "\r"
#expect "Would you like to alter php.ini"
#send "\r"
#expect "Press Enter to continue:"
#send "\r"
#expect eof
#EOD
#)

#會修改 include_path 要跟著修改

#############################################
#安裝php-memcache
makeEnv
sudo mkdir -p /usr/local/webserver/php/etc/php.d/
sudo mkdir -p $DESTDIR/usr/local/webserver/php/etc/php.d/
cd $WORKHOME
test \! -f "memcache-3.0.9.tgz" && \
wget --no-check-certificate -N https://github.com/joetww/work_script/raw/master/memcache-3.0.9.tgz && \
tar zxvf "memcache-3.0.9.tgz" && (
cd memcache-3.0.9 && /usr/local/webserver/php/bin/phpize && \
./configure --with-php-config=/usr/local/webserver/php/bin/php-config --enable-memcache && \
make && sudo make INSTALL_ROOT=$DESTDIR install && \
sudo make install clean && \
sudo sh -c "echo 'extension=memcache.so' > /usr/local/webserver/php/etc/php.d/memcache.ini" && \
sudo sh -c "echo 'extension=memcache.so' > $DESTDIR/usr/local/webserver/php/etc/php.d/memcache.ini"
)

#############################################
#php5只能支援到pecl-memcached 2.x，但是php7支援到pecl-memcached 3
makeEnv
sudo mkdir -p /usr/local/webserver/php/etc/php.d/
sudo mkdir -p $DESTDIR/usr/local/webserver/php/etc/php.d/
PECL_MODULE="memcached-3.0.3"
sudo /usr/local/webserver/php/bin/pecl info $PECL_MODULE 2>&1 > /dev/null && \
sudo /usr/local/webserver/php/bin/pecl uninstall $PECL_MODULE
sudo expect << EOD
spawn /usr/local/webserver/php/bin/pecl install $PECL_MODULE
expect "libmemcached directory"
send "\r"
expect eof
EOD
cp /usr/local/webserver/php/lib/php/extensions/no-debug-non-zts-20151012/memcached.so $DESTDIR/usr/local/webserver/php/lib/php/extensions/no-debug-non-zts-20151012/memcached.so
sudo sh -c "echo 'extension=memcached.so' > /usr/local/webserver/php/etc/php.d/memcached.ini"
sudo sh -c "echo 'extension=memcached.so' > $DESTDIR/usr/local/webserver/php/etc/php.d/memcached.ini"

##############################################
##安裝php-pgsql
#makeEnv
#cd $WORKHOME/php-$PHP_VERSION/ext/pgsql
#$PHP_PATH/bin/phpize && \
#./configure \
#--with-php-config=$PHP_PATH/bin/php-config \
#--with-pgsql=/usr/local/webserver/pgsql && \
#sudo make && sudo make INSTALL_ROOT=$DESTDIR install && sudo make install clean

#############################################
#安裝gearmand 
makeEnv
cd $WORKHOME/ && \
wget --no-check-certificate -N https://github.com/gearman/gearmand/releases/download/1.1.18/gearmand-1.1.18.tar.gz
tar zxvf gearmand-1.1.18.tar.gz && \
cd gearmand-1.1.18 && \
./configure --prefix=/usr/local/webserver/gearmand --with-mysql=/usr/local/webserver/mysql/bin/mysql_config && \
make && \
sudo make install && \
sudo make DESTDIR=$DESTDIR install && \
sudo make clean

#############################################
#安裝php-gearman
# makeEnv
# PECL_MODULE="gearman"
# sudo /usr/local/webserver/php/bin/pecl info $PECL_MODULE 2>&1 > /dev/null && \
# sudo /usr/local/webserver/php/bin/pecl uninstall $PECL_MODULE
# sudo "PATH=$PATH" \
# bash -c "export GEARMAN_LIB_DIR=/usr/local/webserver/gearmand/lib && \
        # export GEARMAN_INC_DIR=/usr/local/webserver/gearmand/include && \
        # /usr/local/webserver/php/bin/pecl install gearman"

makeEnv
cd $WORKHOME/ && \
wget --no-check-certificate -N https://github.com/wcgallego/pecl-gearman/archive/master.zip && \
unzip master.zip && \
cd pecl-gearman-master && \
/usr/local/webserver/php/bin/phpize && \
./configure --with-php-config=/usr/local/webserver/php/bin/php-config --with-gearman=/usr/local/webserver/gearmand && \
make && \
sudo make INSTALL_ROOT=$DESTDIR install && \
sudo make install && \
sudo make clean
sudo sh -c "echo 'extension=gearman.so' > /usr/local/webserver/php/etc/php.d/gearman.ini"
sudo sh -c "echo 'extension=gearman.so' > $DESTDIR/usr/local/webserver/php/etc/php.d/gearman.ini"
	
#############################################
#安裝redis
makeEnv
cd $WORKHOME/ && \
wget --no-check-certificate -N http://download.redis.io/releases/redis-4.0.12.tar.gz
tar zxvf redis-4.0.12.tar.gz
cd redis-4.0.12 && \
make PREFIX=/usr/local/webserver/redis && \
sudo make PREFIX=$DESTDIR/usr/local/webserver/redis install && \
sudo make PREFIX=/usr/local/webserver/redis install && \
sudo make clean


makeEnv
sudo mkdir -p /usr/local/webserver/php/etc/php.d/
sudo mkdir -p $DESTDIR/usr/local/webserver/php/etc/php.d/
PECL_MODULE="redis"
sudo /usr/local/webserver/php/bin/pecl info $PECL_MODULE 2>&1 > /dev/null && \
sudo /usr/local/webserver/php/bin/pecl uninstall $PECL_MODULE
sudo expect << EOD
spawn /usr/local/webserver/php/bin/pecl install $PECL_MODULE
expect "enable igbinary serializer support"
send "\r"
expect "enable lzf compression support"
send "\r"
expect eof
EOD

cp /usr/local/webserver/php/lib/php/extensions/no-debug-non-zts-20151012/redis.so $DESTDIR/usr/local/webserver/php/lib/php/extensions/no-debug-non-zts-20151012/redis.so
sudo sh -c "echo 'extension=redis.so' > /usr/local/webserver/php/etc/php.d/redis.ini"
sudo sh -c "echo 'extension=redis.so' > $DESTDIR/usr/local/webserver/php/etc/php.d/redis.ini"
#############################################

sudo sh -c "echo 'zend_extension=opcache.so' > /usr/local/webserver/php/etc/php.d/opcache.ini"
sudo sh -c "echo 'zend_extension=opcache.so' > $DESTDIR/usr/local/webserver/php/etc/php.d/opcache.ini"

#打包
makeEnv
sudo tar  \
--exclude='./webserver/nginx' \
--exclude='./webserver/mysql' \
--exclude='./webserver/php*' \
--exclude='./webserver/pgsql' \
--exclude='./webserver/ruby' \
--exclude='./webserver/gearmand' \
--exclude='./webserver/redis' \
-zcvf /tmp/local_`date +%Y%m%d-%H`.tgz \
-C $DESTDIR/usr/local/ .


#nginx的打包
makeEnv
sudo tar --exclude='*.old' \
--exclude='./webserver/nginx/conf/*' \
--exclude='./webserver/nginx/html/*' \
--exclude='./webserver/nginx/logs/*' \
-zcvf /tmp/nginx_`date +%Y%m%d-%H`.tgz \
-C $DESTDIR/usr/local/ ./webserver/nginx

#############################################
#mysql的打包
#預設的mysql設定檔位置
#另外請檢查預設的資料目錄位置
#/etc/my.cnf /etc/mysql/my.cnf /usr/local/webserver/mysql/etc/my.cnf ~/.my.cnf
sudo tar \
--exclude='./webserver/mysql/etc/*' \
--exclude='./webserver/mysql/data/*' \
-zcvf /tmp/${PROJOECT}_mysql_`date +%Y%m%d-%H`.tgz \
-C $DESTDIR/usr/local/ ./webserver/mysql
#############################################
#gearmand打包
sudo tar -zcvf /tmp/${PROJOECT}_gearmand_`date +%Y%m%d-%H`.tgz \
-C /usr/local/ ./webserver/gearmand
#############################################
#redis打包
sudo tar -zcvf /tmp/${PROJOECT}_redis_`date +%Y%m%d-%H`.tgz \
-C $DESTDIR/usr/local/ ./webserver/redis

#############################################
#php 5.6.30的打包
#預設設定檔位置
#$PHP_PATH/etc

#php.ini要確認pear的路徑 include_path=".:$PHP_PATH/share/pear"
#若是要用pear，之後若是不需要，則可以略過，目前僅用在安裝pecl-memcache & pecl-memcached
#壓縮包內排除etc目錄內的所有設定檔，要自行從舊的複製出來，
makeEnv
sudo tar \
--exclude='./webserver/php/etc/*' \
-zcvf /tmp/${PROJOECT}_php_`date +%Y%m%d-%H`.tgz \
-C $DESTDIR/usr/local/ ./webserver/php

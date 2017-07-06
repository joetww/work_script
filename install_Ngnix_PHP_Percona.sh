### Nginx+PHP+Percona編譯流程 ###
### wget -q https://raw.githubusercontent.com/joetww/work_script/master/install_Ngnix_PHP_Percona.sh -O - | bash
#版本：
#        nginx-1.13.2
#        ruby-2.4.1
#        rubygems-2.6.12
#        naxsi-0.55.3
#        passenger-5.1.5
#        libmcrypt-2.5.8
#        libmemcached-1.0.18
#        boost_1.64.0
#        postgresql-9.6.3
#        percona-server-5.6.36-82.0(mysql)
#        php 5.6.30
#        php-memcache-2.2.7
#        php-memcached-2.2.0
#        php-gearman-1.1.2
#        re2c 0.16
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

sudo yum -y groupinstall "Development tools"
sudo yum -y install wget zlib-devel openssl-devel curl-devel pcre-devel \
readline-devel libxml2-devel libjpeg-turbo-devel libpng-devel \
freetype-devel openldap-devel cmake expect gperf libevent-devel libuuid-devel

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
        NGINX_SOURCE=`find ~/work -maxdepth 1 -type d -name "nginx*" | sort -V | tail -n 1`
        test -z ${PHP_VERSION+x} && echo "SET PHP_VERSION" && \
        PHP_VERSION=`curl -s http://php.net/downloads.php | \
        grep -P '<h3 id="v5\.6\.\d+" class="title">' | \
        sed -n 's/.*\(5.6.[0-9]\+\).*/\1/p'`
        PHP_PATH=/usr/local/webserver/php`echo $PHP_VERSION | sed 's/\./_/g'`
        mkdir -p $WORKHOME
        #加入ruby的路徑
        test -d /usr/local/webserver/ruby/bin && (
        [[ ":$PATH:" != *":/usr/local/webserver/ruby/bin:"* ]] && PATH="/usr/local/webserver/ruby/bin:${PATH}"
        )
        #加入php的路徑
        test -d $PHP_PATH/bin && (
        [[ ":$PATH:" != *":$PHP_PATH/bin:"* ]] && PATH="$PHP_PATH/bin:${PATH}"
        )
        addString /etc/ld.so.conf.d/local.conf "/usr/local/lib"
        addString /etc/ld.so.conf.d/local.conf "/usr/local/webserver/mysql/lib"
        addString /etc/ld.so.conf.d/local.conf "/usr/local/webserver/gearmand/lib"
        sudo ldconfig
}

#############################################
#安裝re2c
makeEnv
cd $WORKHOME 
wget -N https://github.com/skvadrik/re2c/releases/download/0.16/re2c-0.16.tar.gz
tar zxvf re2c-0.16.tar.gz && \
cd re2c-0.16 && \
./configure && \
make && \
sudo make install clean
#############################################
#安裝libmcrypt 2.5.8
makeEnv
cd $WORKHOME 
wget -N https://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
tar zxvf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure --prefix=/usr/local && \
make && sudo make install clean
#############################################
#安裝libmemcached-1.0.18
makeEnv
cd $WORKHOME
wget -N https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz
tar zxvf libmemcached-1.0.18.tar.gz
cd libmemcached-1.0.18 && \
./configure --prefix=/usr/local && \
make && sudo make install clean
#############################################
#安裝libpg
makeEnv
cd $WORKHOME
wget -N https://ftp.postgresql.org/pub/source/v9.6.3/postgresql-9.6.3.tar.gz
tar zxvf postgresql-9.6.3.tar.gz
cd postgresql-9.6.3 && \
./configure --prefix=/usr/local/webserver/pgsql && \
make && sudo make install clean
#############################################
#安裝boost
makeEnv
cd $WORKHOME
wget -N https://dl.bintray.com/boostorg/release/1.64.0/source/boost_1_64_0.tar.gz
tar zxvf boost_1_64_0.tar.gz
cd boost_1_64_0 && \
./bootstrap.sh && \
./b2 && sudo ./b2 install

#############################################
#編譯ruby 2.4.1
makeEnv
cd $WORKHOME
wget -N https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.1.tar.gz
tar zxvf ruby-2.4.1.tar.gz
cd ruby-2.4.1
./configure --prefix=/usr/local/webserver/ruby && \
make && sudo make install clean

#############################################
#安裝rubygems
makeEnv
cd $WORKHOME
wget -N https://rubygems.org/rubygems/rubygems-2.6.12.tgz
tar zxvf rubygems-2.6.12.tgz
cd rubygems-2.6.12
sudo "PATH=$PATH" /usr/local/webserver/ruby/bin/ruby setup.rb
#############################################
#先抓好nginx source code
makeEnv
cd $WORKHOME
wget -N https://nginx.org/download/nginx-1.13.2.tar.gz
tar zxvf `find ~/work -maxdepth 1 -type f -name "nginx*" | sort -V`
NGINX_SOURCE=`find ~/work -maxdepth 1 -type d -name "nginx*" | sort -V | tail -n 1`
cd $NGINX_SOURCE
#############################################
#這裡先跳去準備安裝passenger，等一下會順便裝好nginx
makeEnv
cd $WORKHOME #其實不在乎在哪裡執行，只是一致一些
#安裝passenger
makeEnv
sudo "PATH=$PATH" /usr/local/webserver/ruby/bin/gem install passenger --no-rdoc --no-ri
#############################################
#用passenger-install-nginx-modul安裝nginx & nginx module
makeEnv
sudo "PATH=$PATH" \
/usr/local/webserver/ruby/bin/passenger-install-nginx-module \
--prefix=/usr/local/webserver/nginx \
--nginx-source-dir=$NGINX_SOURCE \
--languages ruby,python,nodejs \
--auto

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



#############################################
#追加naxsi
makeEnv
cd $WORKHOME && \
wget -N https://github.com/nbs-system/naxsi/archive/0.55.3.tar.gz && \
tar zxvf 0.55.3.tar.gz && \
cd naxsi-0.55.3 && \
NAXSI_PATH=`pwd` && \
cd $NGINX_SOURCE && \
#若是之前是用passenger編譯出來的，裡面部份檔案權限會是root，記得修改
test `stat -c %U Makefile` == "root" && \
sudo chown -R `stat -c "%U:%G" README` ./

#以下兩種編譯：把naxsi做成靜態模組嵌入nginx內，或是做成動態模組待設定載入
#這是靜態模組
CONFIG_ARG=`/usr/local/webserver/nginx/sbin/nginx -V 2>&1 | \
grep 'configure arguments:' | \
sed -r 's/--add(-dynamic){0,1}-module=[^ ]*\/naxsi-[^ ]*\/naxsi_src//g' | \
cut -d : -f 2-`
./configure --add-module=$NAXSI_PATH/naxsi_src $CONFIG_ARG
#這是動態模組
#./configure --add-dynamic-module=$NAXSI_PATH/naxsi_src $CONFIG_ARG
#make && sudo make install clean

#############################################
#若是以後想要單獨編譯動態模組
#重新跑一次configure，因為make clean會把Makefile清除
#makeEnv
#make modules && sudo make install clean

#nginx.conf 內 載入 modules的方法
#load_module modules/ngx_http_naxsi_module.so;
#############################################
#安裝mysql(其實是安裝其分枝 percona)
makeEnv
cd $WORKHOME
wget -N https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.36-82.0/source/tarball/percona-server-5.6.36-82.0.tar.gz
tar zxvf percona-server-5.6.36-82.0.tar.gz
cd percona-server-5.6.36-82.0
mkdir -p bld && cd bld/ && \
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/webserver/mysql .. && \
make && sudo make install clean

#############################################
#安裝PHP 5.6.x
makeEnv
cd $WORKHOME && \
(
        wget http://tw1.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror \
                -O php-$PHP_VERSION.tar.gz --timeout=3 -t 1 || \
        wget http://us2.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror \
                -O php-$PHP_VERSION.tar.gz --timeout=3 -t 1 || \
        wget http://sg2.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror \
                -O php-$PHP_VERSION.tar.gz --timeout=3 -t 1
) && \
tar zxvf php-$PHP_VERSION.tar.gz && \
cd php-$PHP_VERSION && \
./configure \
--prefix=$PHP_PATH \
--with-config-file-path=$PHP_PATH/etc \
--with-mysql=mysqlnd --with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd --with-iconv --with-freetype-dir \
--with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr \
--enable-xml --disable-rpath --enable-bcmath \
--enable-shmop --enable-sysvsem --enable-inline-optimization \
--with-curl --enable-mbregex --enable-fpm \
--enable-mbstring --with-mcrypt  --with-gd --enable-gd-native-ttf \
--with-openssl --with-mhash --enable-pcntl --enable-sockets \
--with-ldap --with-libdir=lib64 --with-ldap-sasl --with-xmlrpc \
--enable-zip --enable-soap --without-pear && \
make && sudo make install clean
#############################################
#假如不存在php.ini的話
#先弄個預設的
makeEnv
test \! -f $PHP_PATH/etc/php.ini && \
sudo cp $WORKHOME/php-$PHP_VERSION/php.ini-production \
$PHP_PATH/etc/php.ini

/usr/local/webserver/php5_6_30/bin/pear version || (
#安裝pear
makeEnv
cd $WORKHOME/ && \
wget -N http://pear.php.net/go-pear.phar && \
sudo expect << EOD
spawn $PHP_PATH/bin/php go-pear.phar
expect "or Enter to continue:"
send "\r"
expect "Would you like to alter php.ini"
send "\r"
expect "Press Enter to continue:"
send "\r"
expect eof
EOD
)

#會修改 include_path 要跟著修改

#############################################
#安裝php-memcache
makeEnv
sudo expect << EOD
spawn $PHP_PATH/bin/pecl install memcache
expect "Enable memcache session handler support"
send "\r"
expect eof
EOD


#############################################
#php5只能支援到pecl-memcached 2.x，但是php7支援到pecl-memcached 3
makeEnv
sudo expect << EOD
spawn $PHP_PATH/bin/pecl install memcached-2.2.0
expect "libmemcached directory"
send "\r"
expect eof
EOD

#############################################
#安裝php-pgsql
makeEnv
cd $WORKHOME/php-$PHP_VERSION/ext/pgsql
$PHP_PATH/bin/phpize && \
./configure \
--with-php-config=$PHP_PATH/bin/php-config \
--with-pgsql=/usr/local/webserver/pgsql && \
make && sudo make install clean

#############################################
#安裝gearmand 
makeEnv
cd $WORKHOME/ && \
wget -N https://github.com/gearman/gearmand/releases/download/1.1.16/gearmand-1.1.16.tar.gz && \
tar zxvf gearmand-1.1.16.tar.gz && \
cd gearmand-1.1.16 && \
./configure --prefix=/usr/local/webserver/gearmand \
        --with-mysql=/usr/local/webserver/mysql/bin/mysql_config \
        --with-postgresql=/usr/local/webserver/pgsql/bin/pg_config && \
make && sudo make install clean
#############################################
#安裝php-gearman
sudo "PATH=$PATH" \
bash -c "export GEARMAN_LIB_DIR=/usr/local/webserver/gearmand/lib && \
        export GEARMAN_INC_DIR=/usr/local/webserver/gearmand/include && \
        /usr/local/webserver/php5_6_30/bin/pecl install gearman"

#############################################

#打包
makeEnv
sudo tar  \
--exclude='./webserver/nginx' \
--exclude='./webserver/mysql' \
--exclude='./webserver/php*' \
--exclude='./webserver/pgsql' \
--exclude='./webserver/ruby' \
--exclude='./webserver/gearmand' \
-zcvf /tmp/local_`date +%Y%m%d-%H`.tgz \
-C /usr/local/ .


#nginx的打包
makeEnv
sudo tar --exclude='*.old' \
--exclude='./webserver/nginx/conf/*' \
--exclude='./webserver/nginx/html/*' \
--exclude='./webserver/nginx/logs/*' \
-zcvf /tmp/nginx_`date +%Y%m%d-%H`.tgz \
-C /usr/local/ ./webserver/nginx ./webserver/ruby
#############################################
#mysql的打包
#預設的mysql設定檔位置
#另外請檢查預設的資料目錄位置
#/etc/my.cnf /etc/mysql/my.cnf /usr/local/webserver/mysql/etc/my.cnf ~/.my.cnf
sudo tar -zcvf /tmp/mysql_`date +%Y%m%d-%H`.tgz \
-C /usr/local/ ./webserver/mysql
#############################################
#gearmand打包
sudo tar -zcvf /tmp/gearmand_`date +%Y%m%d-%H`.tgz \
-C /usr/local/ ./webserver/gearmand
#############################################
#php 5.6.30的打包
#預設設定檔位置
#/usr/local/webserver/php5_6_30/etc

#php.ini要確認pear的路徑 include_path=".:/usr/local/webserver/php5_6_30/share/pear"
#若是要用pear，之後若是不需要，則可以略過，目前僅用在安裝pecl-memcache & pecl-memcached
#壓縮包內排除etc目錄內的所有設定檔，要自行從舊的複製出來，
makeEnv
sudo tar -zcvf /tmp/`ls  /usr/local/webserver/ | grep php5_6 | sort -V | tail -n 1`_`date +%Y%m%d-%H`.tgz \
--exclude='./webserver/php_5_6_*/etc/*' \
-C /usr/local/ ./webserver/`ls  /usr/local/webserver/ | grep php5_6 | sort -V | tail -n 1`

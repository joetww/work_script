### Nginx+PHP+Percona編譯流程 ###
 
#版本：
#	nginx-1.13.2
#	ruby-2.4.1
#	rubygems-2.6.12
#	naxsi-0.55.3
#	passenger-5.1.5
#	libmcrypt-2.5.8
#	percona-server-5.6.36-82.0(mysql)
#       php 5.6.30
#       php-memcached-2.2.0
#注意：
#	WORKHOME & NAXSI_PATH & PHP_VERSION & PHP_PATH 使用時別忘記要確認
#秘訣：
#       sudo 可以設定延長session timeout
#       sudo visudo
#       修改 Defaults        env_reset,timestamp_timeout=30

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
freetype-devel openldap-devel cmake

#############################################
export WORKHOME=~/work/
mkdir -p $WORKHOME
#############################################
#安裝libmcrypt 2.5.8
cd $WORKHOME
wget -N https://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
tar zxvf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure --prefix=/usr/local && \
make && sudo make install clean
#############################################
#安裝libmemcached-1.0.18
cd $WORKHOME
wget -N https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz
tar zxvf libmemcached-1.0.18.tar.gz
cd libmemcached-1.0.18 && \
./configure --prefix=/usr/local && \
make && sudo make install clean
#############################################
#安裝libpg
cd $WORKHOME
wget -N https://ftp.postgresql.org/pub/source/v9.6.3/postgresql-9.6.3.tar.gz
tar zxvf postgresql-9.6.3.tar.gz
cd postgresql-9.6.3 && \
./configure --prefix=/usr/local/webserver/pgsql && \
make && sudo make install clean
#############################################
#編譯ruby 2.4.1
cd $WORKHOME
wget -N https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.1.tar.gz
tar zxvf ruby-2.4.1.tar.gz
cd ruby-2.4.1
./configure --prefix=/usr/local && \
make && sudo make install clean
#############################################
#安裝rubygems
cd $WORKHOME
wget -N https://rubygems.org/rubygems/rubygems-2.6.12.tgz
tar zxvf rubygems-2.6.12.tgz
cd rubygems-2.6.12
sudo /usr/local/bin/ruby setup.rb
#############################################
#先抓好nginx source code
cd $WORKHOME
wget -N https://nginx.org/download/nginx-1.13.2.tar.gz
tar zxvf nginx-1.13.2.tar.gz
cd nginx-1.13.2
#############################################
#這裡先跳去準備安裝passenger，等一下會順便裝好nginx
cd $WORKHOME #其實不在乎在哪裡執行，只是一致一些
#安裝passenger
sudo /usr/local/bin/gem install passenger --no-rdoc --no-ri
#############################################
#用passenger-install-nginx-modul安裝nginx & nginx module
sudo "PATH=$PATH" \
/usr/local/bin/passenger-install-nginx-module \
--prefix=/usr/local/webserver/nginx \
--nginx-source-dir=/home/geoyue/work/nginx-1.13.2 \
--languages ruby,python,nodejs \
--auto

#漫長的等待......

#檢查安裝正確不正確
sudo "PATH=$PATH" /usr/local/bin/passenger-config validate-install
#############################################
#追加naxsi
cd $WORKHOME
wget -N https://github.com/nbs-system/naxsi/archive/0.55.3.tar.gz
tar zxvf 0.55.3.tar.gz
cd naxsi-0.55.3
NAXSI_PATH=`pwd`
cd $WORKHOME/nginx-1.13.2
#若是之前是用passenger編譯出來的，裡面部份檔案權限會是root，記得修改
test `stat -c %U Makefile` == "root" && \
sudo chown -R `stat -c "%U:%G" README` ./

#以下兩種編譯：把naxsi做成靜態模組嵌入nginx內，或是做成動態模組待設定載入
#這是靜態模組
CONFIG_ARG=`/usr/local/webserver/nginx/sbin/nginx -V 2>&1 | \
grep 'configure arguments:' | \
sed -r 's/--add(-dynamic){0,1}-module=[^ ]*\/naxsi-[^ ]*\/naxsi_src//g' | \
cut -d : -f 2-`
./configure  --add-module=$NAXSI_PATH/naxsi_src $CONFIG_ARG
#這是動態模組
#./configure  --add-dynamic-module=$NAXSI_PATH/naxsi_src $CONFIG_ARG
#make && sudo make install clean

#############################################
#若是以後想要單獨編譯動態模組
#重新跑一次configure，因為make clean會把Makefile清除
#make modules && sudo make install clean

#nginx.conf 內 載入 modules的方法
#load_module modules/ngx_http_naxsi_module.so;
#############################################
#安裝mysql(其實是安裝其分枝 percona)
cd $WORKHOME
wget -N https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.36-82.0/source/tarball/percona-server-5.6.36-82.0.tar.gz
tar zxvf percona-server-5.6.36-82.0.tar.gz
cd percona-server-5.6.36-82.0
mkdir -p bld && cd bld/ && \
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/webserver/mysql .. && \
make && sudo make install clean
#############################################
#更新ldconfig
sudo bash -c "cat >> /etc/ld.so.conf.d/local.conf" <<EOD
/usr/local/lib
/usr/local/webserver/mysql/lib
EOD

sudo ldconfig -v
#############################################
#安裝PHP 5.6.x
cd $WORKHOME
PHP_VERSION=`curl -s http://php.net/downloads.php | \
grep -P '<h3 id="v5\.6\.\d+" class="title">' | \
sed -n 's/.*\(5.6.[0-9]\+\).*/\1/p'`
PHP_PATH=/usr/local/webserver/php`echo $PHP_VERSION | sed 's/\./_/g'`
wget -N http://tw1.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror \
-O php-$PHP_VERSION.tar.gz
tar zxvf php-$PHP_VERSION.tar.gz
cd php-$PHP_VERSION
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
#先弄個預設的php.ini
sudo cp $WORKHOME/php-$PHP_VERSION/php.ini-production \
$PHP_PATH/etc/php.ini

#安裝pear
cd $WORKHOME/
wget -N http://pear.php.net/go-pear.phar
sudo $PHP_PATH/bin/php go-pear.phar
#會修改 include_path 要跟著修改
#############################################
#安裝php-memcache
sudo $PHP_PATH/bin/pecl install memcache
#############################################
#php5只能支援到pecl-memcached 2.x，但是php7支援到pecl-memcached 3
sudo $PHP_PATH/bin/pecl install memcached-2.2.0
#############################################
#安裝php-pgsql
cd $WORKHOME/php-$PHP_VERSION/ext/pgsql
$PHP_PATH/bin/phpize && \
./configure \
--with-php-config=$PHP_PATH/bin/php-config \
--with-pgsql=/usr/local/webserver/pgsql && \
make && sudo make install clean
#############################################


#############################################
#打包，放在/tmp底下(注意空間大小)
#nginx/conf nginx/html nginx/logs 這三個目錄不打包
#mysql&php也排除打包在這包，獨立成為自己一包
 
sudo tar --exclude='*.old' --exclude='./webserver/nginx/conf/*' \
--exclude='./webserver/nginx/html/*' \
--exclude='./webserver/nginx/logs/*' \
--exclude='./webserver/mysql' \
--exclude='./webserver/php*' \
--exclude='./webserver/pgsql' \
-zcvf /tmp/webserver_`date +%Y%m%d-%H`.tgz \
-C /usr/local/ .
#############################################
#mysql的打包
#預設的mysql設定檔位置
#另外請檢查預設的資料目錄位置
#/etc/my.cnf /etc/mysql/my.cnf /usr/local/webserver/mysql/etc/my.cnf ~/.my.cnf
sudo tar -zcvf /tmp/mysql_`date +%Y%m%d-%H`.tgz \
-C /usr/local/ ./webserver/mysql
#############################################
#php 5.6.30的打包
#預設設定檔位置
#/usr/local/webserver/php5_6_30/etc

#php.ini要確認pear的路徑 include_path=".:/usr/local/webserver/php5_6_30/share/pear"
#若是要用pear，之後若是不需要，則可以略過，目前僅用在安裝pecl-memcache & pecl-memcached
#壓縮包內排除etc目錄內的所有設定檔，要自行從舊的複製出來，

sudo tar -zcvf /tmp/php_`date +%Y%m%d-%H`.tgz \
--exclude='./webserver/php_5_6_*/etc/*' \
-C /usr/local/ ./webserver/`ls  /usr/local/webserver/ | grep php5_6 | sort -V | tail -n 1`

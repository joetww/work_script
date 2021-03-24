#!/bin/bash

for i in $(ls -d /etc/letsencrypt/live/*/ | awk 'BEGIN{FS="/"}{print $(NF-1)}' );
do
        echo $i.conf
        cat /usr/local/webserver/openresty/nginx/conf/sites-enabled/aiatemplatei | \
        sed 's/<{domain}>/'$i'/g' > /usr/local/webserver/openresty/nginx/conf/sites-enabled/$i.conf;
done

/usr/local/webserver/openresty/nginx/sbin/nginx -t && /usr/local/webserver/openresty/nginx/sbin/nginx -s reload

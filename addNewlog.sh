#!/bin/bash

test \! -f /home/www/nginx/mainaccess.conf && \
cat <<"EOD" > /home/www/nginx/mainaccess.conf
    log_format  mainaccess  '$remote_addr - $remote_user [$time_local] "$request" '
              '$status $body_bytes_sent $request_body "$http_referer" '
              '"$http_user_agent" $http_x_forwarded_for ' $host;

    access_log /home/www/logs/nginx/mainaccess.log mainaccess;
EOD

grep -q 'include /home/www/nginx/mainaccess.conf;' /home/www/nginx/nginx-config.conf || \
sed -i -r '/error_log syslog:server=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+;/a \        include /home/www/nginx/mainaccess.conf;' /home/www/nginx/nginx-config.conf
perl -pi -e 's/\r\n/\n/g' /home/www/nginx/nginx-config.conf


test \! -f /etc/logrotate.d/tengine && \
cat <<"EOD" > /etc/logrotate.d/tengine
/usr/local/nginx/logs/*.log /home/www/logs/nginx/*.log{
  dateext
  dateformat -%Y%m%d%H_%s
  compress
  compresscmd /bin/xz
  compressext .xz
  delaycompress
  notifempty
  size 100M
  minsize 100M
  rotate 120
  missingok
  create 644 www-data root
  sharedscripts
  postrotate
    [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    [ -f /home/www/nginx/nginx.pid ] && kill -USR1 `cat /home/www/nginx/nginx.pid`
    [ -f /home/www/logs/nginx/nginx.pid ] && kill -USR1 `cat /home/www/logs/nginx/nginx.pid`
  endscript
}
EOD


	
sudo /usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf -t && \
sudo /usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf -s reload && \
sleep 2 && \
ls -la /home/www/logs/nginx/mainaccess.log && \
ps aux | grep nginx && \
logrotate -d /etc/logrotate.d/tengine

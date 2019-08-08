#!/bin/sh

GARRAY=()

. /data/shell/gearmand/gearman_list.sh

for (( i=0; i<${#GARRAY[@]};i++));
do
    eval ${GARRAY[$i]};
[ ! -f ${s[1]} ] && /usr/local/webserver/gearmand/sbin/gearmand \
    --log-file ${s[0]} \
    --pid-file ${s[1]} \
    --listen 127.0.0.1 \
    --port=${s[3]} \
    --queue-type=mysql \
    --mysql-host=127.0.0.1 \
    --mysql-port=${MYPORT} \
    --mysql-user=gearmand \
    --mysql-db=${s[2]} \
    --mysql-table=gearman_queue \
    --mysql-password=4Qs6JjN8VyY9 -d
done


ZHTWORKERLIST=()
ZHTWORKERLIST=( \
    Worker_game_setting \
    Worker_business_platform \
    Worker_business_authority \
    Worker_report \
    Worker_blacklist \
    Worker_financial \
    Worker_risk_control \
    Worker_socket \
    Worker_initialize \
    server/ZHT_resque/worker_start/Worker_game_maintenance \
    server/ZHT_resque/worker_start/Worker_resque_scheduler_config \
    server/ZHT_resque/worker_start/Worker_business_platform \
    server/ZHT_resque/worker_start/Worker_financial \
    server/ZHT_resque/worker_start/Worker_monitor \
    server/ZHT_resque/worker_start/Worker_reissue \
    server/ZHT_resque/worker_start/Worker_report \
    server/ZHT_resque/worker_start/Worker_reset_connect \
    server/ZHT_resque/worker_start/Worker_thirdparty \
    server/ZHT_resque/scheduler_start/Worker_game_maintenance \
    server/ZHT_resque/scheduler_start/Worker_resque_scheduler_config \
    server/ZHT_resque/scheduler_start/Worker_business_platform \
    server/ZHT_resque/scheduler_start/Worker_financial \
    server/ZHT_resque/scheduler_start/Worker_monitor \
    server/ZHT_resque/scheduler_start/Worker_reissue \
    server/ZHT_resque/scheduler_start/Worker_report \
    server/ZHT_resque/scheduler_start/Worker_reset_connect \
    server/ZHT_resque/scheduler_start/Worker_thirdparty \
)

PIDFLAG=()

for i in ${ZHTWORKERLIST[*]}; do
    [ ! -z ${WORKERPID} ] && unset WORKERPID
    WORKERPID=`ps -afe | grep "/www/zonghoutai/web/application/index.php ${i}" | grep -v grep | awk '{print $2}'`
    [ ! -z ${WORKERPID} ] && \
    kill -9 `ps -afe | grep "/www/zonghoutai/web/application/index.php ${i}" | grep -v grep | awk '{print $2}'`
    nohup /usr/local/webserver/php/bin/php /www/zonghoutai/web/application/index.php ${i} >> /data/logs/gearmand/worker-zonghoutai.log 2>&1 &
    PIDFLAG+=(${!})
done

echo ${PIDFLAG[*]} > /usr/local/webserver/gearmand/var/worker-zonghoutai.pid

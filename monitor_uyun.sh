#!/bin/bash

INOTIFYWAIT="$(which inotifywait) -mrq --format %w%f"

MONITOR_PATH="/www/tzcloud/"
nohup ${INOTIFYWAIT} --exclude "(.swp|.inc|.svn|.rar|.tar.gz|.gz|.bak|.filepart)" -e MOVED_TO ${MONITOR_PATH} | while read path ;
do
        file=`echo $path | sed 's#'${MONITOR_PATH}'##'`;
        #printf "[%s][%s]\t%s\n" "`date +"%F %T"`" "`basename ${MONITOR_PATH}`" "${file}" >> /data/logs/Update_$(date +"%F").log;
        #sleep 10;
        printf "[%s][%s]\t%s\n" "`date +"%F %T"`" "`basename ${MONITOR_PATH}`" "${file}" >> /data/logs/Update_$(date +"%F").log;

        (
                echo ${file} | grep -qE "client_full.zip|mobile_android.apk|client.zip" || \
                {
                        /data/shell/ucloud/RefreshUcdn.py $file >> /data/logs/ucloud_$(date +"%F").log 2>&1;
                        /usr/bin/python /data/shell/cloudfront/invalidate.py $file >> /data/logs/cloudfront_$(date +"%F").log 2>&1;
                        false;
                }
        ) && \
        (
                bucket="bbapk";
                speedlimit=250000;

                /data/shell/ufile/filemgr-linux64 --action mput --bucket $bucket --key ${file} --file ${path} --speedlimit ${speedlimit} >> /data/logs/ufile_$(date +"%F").log 2>&1;
                /data/shell/ucloud/RefreshUcdn.bb2apk.py ${file} >> /data/logs/ufile_$(date +"%F").log 2>&1;
        )
done &


#常常自己卡住，所以獨立出來
MONITOR_PATH="/www/tzcloud/"
nohup ${INOTIFYWAIT} --exclude "(.swp|.inc|.svn|.rar|.tar.gz|.gz|.bak|.filepart)" -e MOVED_TO ${MONITOR_PATH} | while read path ;
do
        file=`echo $path | sed 's#'${MONITOR_PATH}'##'`;
        printf "[%s][%s]\t%s\n" "`date +"%F %T"`" "`basename ${MONITOR_PATH}`" "${file}" >> /data/logs/Update_$(date +"%F").log;
        /usr/bin/php /data/shell/webluker/webluker_refresh.php "http://tzwbyun.bjjyc.net/$file" >> /data/logs/webluker_$(date +"%F").log 2>&1;
done &

MONITOR_PATH="/www/tzsslcloud/"
nohup ${INOTIFYWAIT} --exclude "(.swp|.inc|.svn|.rar|.tar.gz|.gz|.bak|.filepart)" -e MOVED_TO ${MONITOR_PATH} | while read path ;
do
        tmpfile=$(mktemp /tmp/qiniu-script.XXXXXX);
        file=`echo $path | sed 's#/www/tzsslcloud/##'`;
        printf "[%s][%s]\t%s\n" "`date +"%F %T"`" "`basename ${MONITOR_PATH}`" "${file}" >> /data/logs/Update_$(date +"%F").log;

        echo $path | sed 's/\/www\/tzsslcloud/https\:\/\/tzsslyun\.bjjyc\.net/' > ${tmpfile};
        /usr/bin/qshell fput tzssl $file $path true >> /data/logs/qiniu_$(date +"%F").log 2>&1;
        /usr/bin/qshell cdnrefresh ${tmpfile} >> /data/logs/qiniu_$(date +"%F").log 2>&1;
        rm "${tmpfile}" ;
done &

#!/bin/bash
#RSS代表實體記憶體的使用量。但是這裡RSS的值，是包括shared memory的。

PROCESSLIST="php-fpm nginx redis-server mysqld gearmand memcached php bash sh"

for i in ${PROCESSLIST}
do
    SUM=$(ps --no-headers -o "rss,cmd" -C ${i} | awk '{ sum+=$1 } END { printf ("%d%s\n", sum/1024,"M") }')
    AVG=$(ps --no-headers -o "rss,cmd" -C ${i} | awk '{ sum+=$1 } END { printf ("%d%s\n", sum/NR/1024,"M") }')

    printf "%-10s\tSUM: %-6s\tAVG: %-6s\n" ${i} ${SUM} ${AVG}
done

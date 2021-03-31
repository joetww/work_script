#!/bin/bash

PROCESSLIST="php-fpm nginx redis-server mysqld gearmand memcached php bash sh"
echo "用pmap計算，不記入 shared memory"
for i in ${PROCESSLIST}
do
    PIDS=$(ps --no-headers -o "pid" -C ${i})
    PMAPS=$(for j in ${PIDS}
    do
        sudo pmap -d ${j} | grep -Pho 'writeable\/private:\s\d+' | awk '{print $2}'
    done )
    SUM=$(echo "$PMAPS" | awk '{ sum+=$1 } END { printf ("%d%s\n", sum/1024,"M") }')
    AVG=$(echo "$PMAPS" | awk '{ sum+=$1 } END { printf ("%d%s\n", sum/NR/1024,"M") }')

    printf "%-10s\tSUM: %-6s\tAVG: %-6s\n" ${i} ${SUM} ${AVG}
done

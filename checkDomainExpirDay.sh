#!/bin/bash

#需要查詢的域名
. /data/shell/DomainNameList.sh

#整理一下只留下二級域名
MainDomain=$(
for i in ${DOMAIN}; do
    dot=$(echo ${i} | grep -o '\.' | wc -l)
    test ${dot} -eq 1 && echo ${i}
    test ${dot} -ge 2 && echo ${i} | grep -oP '[^\.]+\.[^\.]+$'
done | sort -u)

for i in ${MainDomain}; do
    #先找到上層的whois server
    TOPWHOIS=$(whois -h whois.iana.org ${i} | grep -iPo 'whois:\s+.*' | awk '{print $2}')
    #只想知道哪時候過期
    EXPIRDAY=$(whois -h ${TOPWHOIS} ${i} | grep -iP 'Expir(ation)*' | grep -Po '\d{4}-\d{2}-\d{2}')
    printf "%-16s\t%-16s\t%s\t%4d\n" "${i}" "${TOPWHOIS}" "${EXPIRDAY}" $(echo \($(date --date="${EXPIRDAY}" +%s) - $(date +%s)\) / \(60 \* 60 \* 24\) | bc)
done | sort -k4n

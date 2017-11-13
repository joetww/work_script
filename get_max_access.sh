#!/bin/sh


function join_by { local IFS="$1"; shift; echo "$*"; }

OLDIFS=${IFS}

IFS=$'\n';
BADSTRING="
phpmyadmin
killall -9 perl
/cgi-bin/test-cgi
invoker/EJBInvokerServlet
die\(md5\(\[^\)]+\)\)
"


BADSTRINGCOMMAND=`join_by \| ${BADSTRING}`

IFS=${OLDIFS};

WHITELIST="
    1.2.3.4
    5.6.7.8
    8.8.8.8
    8.8.4.4
"
VERYBADLIST="
    182.118.33.6
    182.118.33.7
    220.181.55.144
    223.94.89.20
"
GREPCOMMAND=$(
    join_by \| ${WHITELIST}
)


echo "排除的IP"
echo "$GREPCOMMAND"

echo "壞字串"
echo "$BADSTRINGCOMMAND"

echo
NEW_BAD_LIST=$(
    c=1;
    (
    for i in `cat ~/seoproxylist.txt | grep -v ^$ |  head -n 20 `
    do
        >&2 printf "proxy %02d\t%-15s\n" ${c} ${i};
        (
            ssh -o StrictHostKeyChecking=no joeyue@${i} "function join_by { local IFS=\"\$1\"; shift; echo \"\$*\"; }; TIMELOG=\$(join_by \| \$(for i in {1..10}; do date -d \"\${i} minute ago \" +\"%d/%b/%Y:%H:%M\"; done)); sudo cat /usr/local/webserver/openresty/nginx/logs/access | ( grep -P '('\${TIMELOG}')' ) | awk '{print \$1}' | gzip ;" ;
        );
        c=`expr ${c} + 1`;
    done
    ) | zcat | sort | uniq -c | sort -n | awk '$1 > 5000{print $2}';

    ( 
    for i in `cat ~/seoproxylist.txt | grep -v ^$ |  head -n 20 `
    do
        (
            ssh -o StrictHostKeyChecking=no joeyue@${i} "sudo cat /usr/local/webserver/openresty/nginx/logs/access | grep -P '($(date +"%d/%b/%Y")|$(date -d "1 day ago" +"%d/%b/%Y"))' | grep -P '(${BADSTRINGCOMMAND})' | awk '{print \$1}' | sort -u | gzip ; ";
            ssh -o StrictHostKeyChecking=no joeyue@${i} "function join_by { local IFS=\"\$1\"; shift; echo \"\$*\"; }; TIMELOG=\$(join_by \| \$(for i in {1..10}; do date -d \"\${i} minute ago \" +\"%d/%b/%Y:%H:%M\"; done)); sudo cat /usr/local/webserver/openresty/nginx/logs/access | grep -P '.*?([0-9]{1,3}\.){3}[0-9]+$' | grep -P '('\${TIMELOG}')' | awk '{print \$1}' | sort -nu | gzip ;" ;
        );
    done
    ) | zcat | sort -un ;
) ;
#echo "${NEW_BAD_LIST}"
BLACKLIST_SETTING=$(
    ssh -o StrictHostKeyChecking=no joeyue@`cat ~/seoproxylist.txt | grep -v ^$ | head -n 1 ` "sudo /usr/sbin/ipset save blacklist"
)

echo ;
for i in {1..30}; do printf "="; done
echo ;
RENEW_BLACKLIST=$(
    
    for i in ${VERYBADLIST}
    do
        printf "%s %-15s %s %-6d ;\n" "sudo /usr/sbin/ipset -exist add blacklist " ${i} "timeout" `expr 24 \* 60 \* 60`
    done | grep -v -P '('$GREPCOMMAND')' ;
    for i in $WHITELIST;
    do
        printf "sudo ipset save | grep --silent \"^add blacklist %s\" && %s %-15s ;\n" ${i} "sudo /usr/sbin/ipset del blacklist " ${i} ;
    done
    for i in $(
        echo "${NEW_BAD_LIST}" | grep -v -P '('$GREPCOMMAND')' | grep -v -P '('$(join_by \| ${VERYBADLIST})')' ;
    );
    do
        printf "sudo ipset save | grep --silent \"^add blacklist %s\" || %s %-15s ;\n" ${i} "sudo /usr/sbin/ipset add blacklist " ${i} ;
    done | sort -u
)

echo "("$(echo "${RENEW_BLACKLIST}" | head -n 30 | wc -l)"/"$(echo "${RENEW_BLACKLIST}" | wc -l)")"
echo "${RENEW_BLACKLIST}" | head -n 30;


echo 
echo "塞資料入proxy";
for i in `cat ~/seoproxylist.txt | grep -v ^$ |  head -n 20 `
do
    echo .
    ssh -o StrictHostKeyChecking=no joeyue@${i} "${RENEW_BLACKLIST}"
done

#!/bin/bash

for j in hksslyun02.bjjyc.net hksslyun01.bjjyc.net tzupyun.bjjyc.net tzsslyun.bjjyc.net tzcloud.bjjyc.net;
do
    printf "%-28s\t%s\n"    "$j" \
                            "$(curl -v https://${j} 2>&1 | awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }' | grep 'expire date')";
done

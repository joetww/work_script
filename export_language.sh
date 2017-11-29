#!/bin/sh

display_usage() {
        echo -e "\nUsage:\n$0 [<dev|pre|pro>] \n"
}

if [ $# -lt 1 ]
then
        display_usage
        exit 1
fi

case "${1,,}" in
        dev)    echo "Dev"
                TARGETIP="10.64.145.102"
                TARGETPORT=27777
                TARGETPATH="/www/tingzhu/trunk/application/language"
                LANGUAGEPATH="/www/zonghoutai/trunk/web/application/export/language"
        ;;
        pre)
                echo "Pre"
                TARGETIP="192.168.8.21"
                TARGETPORT=27777
                TARGETPATH="/www/pre/tingzhu/trunk/application/language"
                LANGUAGEPATH="/www/zonghoutai/trunk/web/application/export/language"
        ;;
        pro)
                echo "Pro"
                TARGETIP="192.168.8.21"
                TARGETPORT=27777
                TARGETPATH="/www/tingzhu/trunk/application/language"
                LANGUAGEPATH="/www/zonghoutai/trunk/web/application/export/language"
        ;;
        *)      display_usage
                exit 2
        ;;
esac
#LANGUAGEPATH=$(find /www/zonghoutai/{branch,trunk} -type d -name "language" 2>/dev/null | grep "export/" | tail -n 1)
#OLDPWD=$(pwd)
cd ${LANGUAGEPATH}
printf "%30s\t-->\t%30s\n" $LANGUAGEPATH $TARGETPATH
LISTFILE=$(find . \( -path ./.svn -o -path ./index.html \) -prune -o \( -type f -print \))
find . \( -path ./.svn -o -path ./index.html \) -prune -o \( -type f -ls \)
#tar zcf - $(echo ${LISTFILE}) | \
#ssh $USER@${TARGETIP} -p${TARGETPORT} "mkdir -p ~/language; tar zcf ~/language/old_language_`date +\%Y\%m\%d_\%H\%M\%S`.tgz -C ${TARGETPATH} . --exclude-vcs && tar zxvf - -C ${TARGETPATH} "

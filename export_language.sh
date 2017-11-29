#!/bin/sh
#也可以這樣子執行
# Usage: curl -s https://raw.githubusercontent.com/joetww/work_script/master/export_language.sh | bash /dev/stdin [<dev|pre|pro>]
display_usage() {
        echo -e "\nUsage:\n$0 [<dev|pre|pro>] [useraccount]\n"
}

check_ip() {
        getIP=$(ifconfig | grep -Eo 'inet (addr:)?((192\.168\.|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)([0-9]*\.){1,2})[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
        [[ ${getIP} != ${SOURCEIP} ]] && { echo -e "\nRun on wrong IP:\n${getIP}\n" ; exit 3; }
}

if [ $# -lt 1 ]
then
        display_usage
        exit 1
fi

TARGETUSER=${2:-root}

case "${1,,}" in
        dev)    echo "Dev"
                TARGETIP="10.64.145.102"
                TARGETPORT=27777
                TARGETPATH="/www/tingzhu/trunk/application/language"
                SOURCEIP="10.64.145.101"
                LANGUAGEPATH="/www/zonghoutai/trunk/web/application/export/language"
        ;;
        pre)
                echo "Pre"
                TARGETIP="192.168.8.21"
                TARGETPORT=27777
                TARGETPATH="/www/pre/tingzhu/trunk/application/language"
                SOURCEIP="192.168.8.25"
                LANGUAGEPATH="/www/zonghoutai/trunk/web/application/export/language"
        ;;
        pro)
                echo "Pro"
                TARGETIP="192.168.8.21"
                TARGETPORT=27777
                TARGETPATH="/www/tingzhu/trunk/application/language"
                SOURCEIP="192.168.8.25"
                LANGUAGEPATH="/www/zonghoutai/trunk/web/application/export/language"
        ;;
        *)      display_usage
                exit 2
        ;;
esac

check_ip
#LANGUAGEPATH=$(find /www/zonghoutai/{branch,trunk} -type d -name "language" 2>/dev/null | grep "export/" | tail -n 1)
#OLDPWD=$(pwd)
cd ${LANGUAGEPATH}
printf "%s: %-60s\t-->\t%s: %-60s\n" $SOURCEIP $LANGUAGEPATH $TARGETIP $TARGETPATH
LISTFILE=$(find . \( -path ./.svn -o -path ./index.html \) -prune -o \( -type f -print \))
find . \( -path ./.svn -o -path ./index.html \) -prune -o \( -type f -ls \)
tar zcf - $(echo ${LISTFILE}) | \
ssh ${TARGETUSER}@${TARGETIP} -p${TARGETPORT} "mkdir -p ~/language; sudo tar zcf ~/language/old_language_`date +\%Y\%m\%d_\%H\%M\%S`.tgz -C ${TARGETPATH} . --exclude-vcs && sudo tar zxvf - -C ${TARGETPATH} "

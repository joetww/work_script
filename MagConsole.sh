#!/usr/bin/bash
#反向ssh tunnel + socat 轉向snmp port供 cacti用
#
#有的監控端透過特別的方法綁定IP，所以不一定是對應到localhost
#

REMOTE_CONNECT="maxi@52.193.0.52"
REMOTE_PORT=9100
REMOTE_SOCAT_DIR="~/socat_log/"
MONITOR_PORT=20000
LOCAL_PORT=9000
LOCAL_IP="localhost" ## 有時候不一定綁定到localhost(127.0.0.1)


AUTOSSH_PIDFILE="/tmp/MagConsole.AutoSSH.pid"
export AUTOSSH_PIDFILE
AUTOSSH_LOGFILE="/tmp/MagConsole.AutoSSH.log"
export AUTOSSH_LOGFILE


test \! -f  ${AUTOSSH_PIDFILE} && \
/usr/bin/autossh -M ${MONITOR_PORT} -NfR ${REMOTE_PORT}:${LOCAL_IP}:${LOCAL_PORT} ${REMOTE_CONNECT}

nohup socat -s tcp4-listen:${LOCAL_PORT},reuseaddr,fork UDP:${LOCAL_IP}:161 > /tmp/MagConsole.socat.out.log 2> /tmp/MagConsole.socat.error.log < /dev/null &

ssh ${REMOTE_CONNECT} "test \! -d ${REMOTE_SOCAT_DIR} && mkdir -p ${REMOTE_SOCAT_DIR}; cd ~/socat_log && sh -c '(( nohup socat udp4-RECVFROM:'$(expr ${REMOTE_PORT} + 61)',reuseaddr,fork tcp:localhost:'${REMOTE_PORT}' > '${REMOTE_SOCAT_DIR}'/'$(hostname)'.socat.out.log 2> '${REMOTE_SOCAT_DIR}'/'$(hostname)'.socat.error.log < /dev/null ) & )'"

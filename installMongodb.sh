#!/bin/bash

[[ ":$PATH:" != *":/usr/local/webserver/mongodb/bin:"* ]] && PATH="/usr/local/webserver/mongodb/bin:${PATH}"
useradd -d /home/mongod -u 503 -g 503 mongod

wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-4.0.11.tgz && \
tar zxvf mongodb-linux-x86_64-rhel62-4.0.11.tgz -C /usr/local/webserver && \
mv /usr/local/webserver/mongodb-linux-x86_64-rhel62-4.0.11 /usr/local/webserver/mongodb

mkdir -p /usr/local/webserver/mongodb/etc /usr/local/webserver/mongodb/db /usr/local/webserver/mongodb/var/run/mongodb /data/logs/mongodb

chown -R mongod:mongod /usr/local/webserver/mongodb /data/logs/mongodb 

cat <<"EOF" > /etc/init.d/mongod
#!/bin/bash

# mongod - Startup script for mongod

# chkconfig: 35 85 15
# description: Mongo is a scalable, document-oriented database.
# processname: mongod
# config: /etc/mongod.conf

. /etc/rc.d/init.d/functions
MONGODB_PATH=/usr/local/webserver/mongodb

# NOTE: if you change any OPTIONS here, you get what you pay for:
# this script assumes all options are in the config file.
CONFIGFILE="$MONGODB_PATH/etc/mongod.conf"
OPTIONS=" -f $CONFIGFILE"

mongod=${MONGOD-$MONGODB_PATH/bin/mongod}

MONGO_USER=mongod
MONGO_GROUP=mongod

# All variables set before this point can be overridden by users, by
# setting them directly in the SYSCONFIG file. Use this to explicitly
# override these values, at your own risk.
SYSCONFIG="/etc/sysconfig/mongod"
if [ -f "$SYSCONFIG" ]; then
    . "$SYSCONFIG"
fi

# Handle NUMA access to CPUs (SERVER-3574)
# This verifies the existence of numactl as well as testing that the command works
NUMACTL_ARGS="--interleave=all"
if which numactl >/dev/null 2>/dev/null && numactl $NUMACTL_ARGS ls / >/dev/null 2>/dev/null
then
    NUMACTL="numactl $NUMACTL_ARGS"
else
    NUMACTL=""
fi

# things from mongod.conf get there by mongod reading it
PIDFILEPATH="`awk -F'[:=]' -v IGNORECASE=1 '/^[[:blank:]]*(processManagement\.)?pidfilepath[[:blank:]]*[:=][[:blank:]]*/{print $2}' \"$CONFIGFILE\" | tr -d \"[:blank:]\\"'\" | awk -F'#' '{print $1}'`"
PIDDIR=`dirname $PIDFILEPATH`
start()
{
  # Make sure the default pidfile directory exists
  if [ ! -d $PIDDIR ]; then
    install -d -m 0755 -o $MONGO_USER -g $MONGO_GROUP $PIDDIR
  fi
  # Make sure the pidfile does not exist
  if [ -f "$PIDFILEPATH" ]; then
      echo "Error starting mongod. $PIDFILEPATH exists."
      RETVAL=1
      return
  fi
  # Recommended ulimit values for mongod or mongos
  # See http://docs.mongodb.org/manual/reference/ulimit/#recommended-settings
  #
  ulimit -f unlimited
  ulimit -t unlimited
  ulimit -v unlimited
  ulimit -n 64000
  ulimit -m unlimited
  ulimit -u 64000
  ulimit -l unlimited
  echo -n $"Starting mongod: "
  daemon --user "$MONGO_USER" --check $mongod "$NUMACTL $mongod $OPTIONS >/dev/null 2>&1"
  RETVAL=$?
  echo
  [ $RETVAL -eq 0 ] && touch /var/lock/subsys/mongod
}
stop()
{
  echo -n $"Stopping mongod: "
  mongo_killproc "$PIDFILEPATH" $mongod
  RETVAL=$?
  echo
  [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/mongod
}
restart () {
        stop
        start
}
# Send TERM signal to process and wait up to 300 seconds for process to go away.
# If process is still alive after 300 seconds, send KILL signal.
# Built-in killproc() (found in /etc/init.d/functions) is on certain versions of Linux
# where it sleeps for the full $delay seconds if process does not respond fast enough to
# the initial TERM signal.
mongo_killproc()
{
  local pid_file=$1
  local procname=$2
  local -i delay=300
  local -i duration=10
  local pid=`pidofproc -p "${pid_file}" ${procname}`
  kill -TERM $pid >/dev/null 2>&1
  usleep 100000
  local -i x=0
  while [ $x -le $delay ] && checkpid $pid; do
    sleep $duration
    x=$(( $x + $duration))
  done
  kill -KILL $pid >/dev/null 2>&1
  usleep 100000
  checkpid $pid # returns 0 only if the process exists
  local RC=$?
  [ "$RC" -eq 0 ] && failure "${procname} shutdown" || rm -f "${pid_file}"; success "${procname} shutdown"
  RC=$((! $RC)) # invert return code so we return 0 when process is dead.
  return $RC
}
RETVAL=0
case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart|reload|force-reload)
    restart
    ;;
  condrestart)
    [ -f /var/lock/subsys/mongod ] && restart || :
    ;;
  status)
    status $mongod
    RETVAL=$?
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart}"
    RETVAL=1
esac
exit $RETVAL
EOF

cat <<"EOD" > /usr/local/webserver/mongodb/etc/mongod.conf
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /data/logs/mongodb/mongod.log
  logRotate: rename
  timeStampFormat: ctime

# Where and how to store data.
storage:
  dbPath: /usr/local/webserver/mongodb/db
  journal:
    enabled: true
#  engine:
#  wiredTiger:
  indexBuildRetry: true #重启时，重建不完整的索引

# how the process runs
processManagement:
  fork: true  # fork and run in background
  pidFilePath: /usr/local/webserver/mongodb/var/run/mongodb/mongod.pid  # location of pidfile
  timeZoneInfo: /usr/share/zoneinfo

# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1  # Enter 0.0.0.0,:: to bind to all IPv4 and IPv6 addresses or, alternatively, use the net.bindIpAll setting.
  ipv6: false

#security:

operationProfiling:
  slowOpThresholdMs: 100 #认定为查询速度缓慢的时间阈值，超过该时间的查询即为缓慢查询，会被记录到日志中, 默认100
  mode: slowOp #operationProfiling模式 off/slowOp/all 默认off
#replication:

#sharding:

## Enterprise-Only Options

#auditLog:

#snmp:

EOD


chmod a+x /etc/init.d.mongod
chkconfig mongod on
service mongod start

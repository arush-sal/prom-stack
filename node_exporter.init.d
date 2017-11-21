#!/bin/sh

### BEGIN INIT INFO
# Provides:          Node exporter
# Required-Start:    $local_fs $network $named $time $syslog
# Required-Stop:     $local_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Node exporter for prometheus written in Go
### END INIT INFO

DAEMON=/usr/local/bin/node_exporter
NAME=node_exporter
USER=node_exporter
PIDFILE=/var/run/node_exporter/$NAME.pid
LOGFILE=/var/log/node_exporter/$NAME.log

ARGS=""
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

do_start_prepare()
{
    mkdir -p `dirname $PIDFILE` || true
    touch $PIDFILE
    mkdir -p `dirname $LOGFILE` || true
}

do_start_cmd()
{
    do_start_prepare
    echo -n "Starting daemon: "$NAME
    nohup $DAEMON $ARGS >> $LOGFILE 2>&1 & echo "$!" > "$PIDFILE"
    echo " OK."
}

do_stop_cmd()
{
    if [ ! -f "$PIDFILE" ]; then
      # not running; per LSB standards this is "ok"
      echo "Stopping $NAME: " /bin/true
      return 0
    fi
    PID=`cat "$PIDFILE"`
    if [ -n "$PID" ]; then
      /bin/kill "$PID" >/dev/null 2>&1
      RETVAL=$?
      if [ $RETVAL -ne 0 ]; then
        RETVAL=1
        echo "Stopping $NAME: " /bin/false
      else
        echo "Stopping $NAME: " /bin/true
      fi
    else
      # failed to read pidfile
      echo "Stopping $NAME: " /bin/false
      RETVAL=4
    fi
    # if we are in halt or reboot runlevel kill all running sessions
    # so the TCP connections are closed cleanly
    if [ "x$runlevel" = x0 -o "x$runlevel" = x6 ] ; then
      trap '' TERM
      killall $NAME 2>/dev/null
      trap TERM
    fi
    [ $RETVAL -eq 0 ] && rm -f "$PIDFILE"
    return $RETVAL
}

status() {
        printf "%-50s" "Checking $NAME..."
    if [ -f $PIDFILE ]; then
        PID=$(cat $PIDFILE)
            if [ -z "$(ps axf | grep ${PID} | grep -v grep)" ]; then
                printf "%s\n" "The process appears to be dead but pidfile still exists"
            else    
                echo "Running, the PID is $PID"
            fi
    else
        printf "%s\n" "Service not running"
    fi
}


case "$1" in
  start)
    do_start_cmd
    ;;
  stop)
    do_stop_cmd
    ;;
  status)
    status
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $1 {start|stop|status|restart}"
    exit 1
esac

exit 0

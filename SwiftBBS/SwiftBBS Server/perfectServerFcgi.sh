#! /bin/sh

CWD=`dirname "${0}"`
cd "${CWD}"
PIDFILE="perfectserverfcgi.pid"

do_start() {
  if [ -e $PIDFILE ]; then
    echo "already started, because $PIDFILE exists"
    exit 1
  fi

  perfectserverfcgi &
  echo $! > $PIDFILE
  echo "start PID=$!"
}

do_stop() {
  if [ ! -e $PIDFILE ]; then
    echo "not started"
    exit 1
  fi

  PID=$(cat $PIDFILE)
  kill -9 $PID
  rm $PIDFILE
  echo "stop PID=$PID"
}

case "$1" in
  start)
    do_start
    ;;
  stop)
    do_stop
    ;;
  restart)
    do_stop
    do_start
    ;;
esac

exit 0


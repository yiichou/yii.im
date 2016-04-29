#!/bin/sh
set -e

# Feel free to change any of the following variables for your app:
APP_ROOT=/var/www/yii.im
PID_DIR=$APP_ROOT/tmp/pids
PID=$PID_DIR/puma.pid
STATE=$PID_DIR/puma.state

START_CMD="cd $APP_ROOT; bundle exec puma -q -C $PID_DIR/config/puma.rb --daemon"
RESTART_CMD="cd $APP_ROOT; bundle exec pumactl -S $STATE phased-restart"
AS_USER=live
set -u

sig () {
  test -s "$PID" && kill -$1 `cat $PID`
}

run () {
  if [ "$(id -un)" = "$AS_USER" ]; then
    eval $1
  else
    su -c "$1" - $AS_USER
  fi
}

case "$1" in
start)
  sig 0 && echo >&2 "Already running" && exit 0
  run "$START_CMD"
  ;;
stop)
  run "cd $APP_ROOT; bundle exec pumactl -S $STATE stop" && exit 0
  echo >&2 "Not running"
  ;;
status)
  run "cd $APP_ROOT; bundle exec pumactl -S $STATE status" && exit 0
  ;;
halt)
  run "cd $APP_ROOT; bundle exec pumactl -S $STATE halt" && exit 0
  ;;
force_stop)
  sig QUIT && exit 0
  echo >&2 "Not running"
  ;;
restart)
  run "$RESTART_CMD" && echo reloaded OK && exit 0
  echo >&2 "Couldn't reload, starting '$START_CMD' instead"
  ;;
*)
  echo >&2 "Usage: $0 <start|stop|force_stop|restart|status|halt>"
  exit 1
  ;;
esac
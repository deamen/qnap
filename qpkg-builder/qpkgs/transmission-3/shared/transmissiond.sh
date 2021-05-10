#!/bin/sh
CONF=/etc/config/qpkg.conf
QPKG_NAME="transmission-daemon"
QPKG_ROOT=`/sbin/getcfg $QPKG_NAME Install_Path -f ${CONF}`
export QNAP_QPKG=$QPKG_NAME


function start_transmission_daemon {
    export CURL_CA_BUNDLE="${QPKG_ROOT}/etc/ssl/certs/cacert.pem"
    TRANSMISSION_WEB_HOME=${QPKG_ROOT}/usr/local/share/transmission/web/ ${QPKG_ROOT}/usr/local/bin/transmission-daemon -f -t --blocklist -g ${QPKG_ROOT}/etc/transmission-daemon.d &
}

case "$1" in
  start)
    ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
    if [ "$ENABLED" != "TRUE" ]; then
        echo "$QPKG_NAME is disabled."
        exit 1
    fi
    start_transmission_daemon
    ;;

  stop)
    killall transmission-daemon
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0

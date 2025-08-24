#!/usr/bin/env bash

# Environment variables
SCRIPT_DIR=$(dirname $0)
WORKDIR=$(cd $SCRIPT_DIR; echo $PWD)

# Load config variables
#[ -f /etc/pwmon/pwmon.conf ] && source /etc/pwmon/pwmon.conf
source $WORKDIR/pwmon.conf

# Helper functions
batteryPoller () {
  BATTERY_STATE=$(cat $BATTERY_PATH/status)
  BATTERY_CAPACITY=$(cat $BATTERY_PATH/capacity)

  if [ $BATTERY_CAPACITY -lt 35 ]; then
    case $BATTERY_STATE in
      Discharging)
        log "info" "Low battery: $BATTERY_CAPACITY%. Toggling AC adapter ON"
        togglePower
        ;;
      Charging)
        log "debug" "AC adapter already ON"
        ;;
    esac

  elif [ $BATTERY_CAPACITY -gt 75 ]; then
    case $BATTERY_STATE in
      Discharging)
        log "debug" "AC adapter already OFF"
        ;;
      Charging)
        log "info" "Battery charged: $BATTERY_CAPACITY%. Toggling AC adapter OFF"
        togglePower
        ;;
    esac
  fi
}

togglePower () {
  AC_STATE=$(/root/kasa/bin/kasa --alias $KASA_AC_PLUG_NAME state |grep State |sed 's/.*: //g')
  log "info" "AC Power: $AC_STATE"
  case $AC_STATE in
    False)
      /root/kasa/bin/kasa --alias $KASA_AC_PLUG_NAME on
      ;;
    True)
      /root/kasa/bin/kasa --alias $KASA_AC_PLUG_NAME off
      ;;
  esac
}

log () {
  case $1 in
    debug)
      [ $DEBUG = "true" ] && echo "DEBUG: $2"
      ;;
    info)
      echo "INFO: $2"
      ;;
    error)
      echo "ERROR: $2"
      ;;
    banner)
      echo 
      echo "INFO: $2"
      echo 
      ;;
    *)
      echo "USPEC: $2"
      ;;
  esac
}

# Log banner info info
start_msg="Variables configured on $WORKDIR/pwmon.conf:
      KASA_AC_PLUG_NAME=$KASA_AC_PLUG_NAME
      BATTERY_PATH=$BATTERY_PATH"
log "banner" "$start_msg"

# Entrypoint, main loop
while [ true ]
do
  batteryPoller
  sleep 60
done

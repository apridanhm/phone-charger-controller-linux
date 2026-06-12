#!/bin/bash

LOG="/var/log/phone-charge.log"

ANDROID_VENDOR="2717"
IPHONE_VENDOR="05ac"

MIN_BAT=20
MAX_BAT=97

# test dulu
CHECK_INTERVAL=3600
# production nanti
# CHECK_INTERVAL=1800

################################

log() {
echo "$(date '+%F %T')  $1" | tee -a "$LOG"
}

################################

power_on_hubs() {

uhubctl | awk '/Current status for hub/ {print $5}' | while read hub; do
    uhubctl -l "$hub" -a on >/dev/null 2>&1
done

}

################################

detect_ports() {

ANDROID_PORT=""
ANDROID_HUB=""

IPHONE_PORT=""
IPHONE_HUB=""

CURRENT_HUB=""

while read -r line; do

if [[ $line == Current*hub* ]]; then
CURRENT_HUB=$(echo "$line" | awk '{print $5}')
fi

if echo "$line" | grep -q "$ANDROID_VENDOR"; then
ANDROID_PORT=$(echo "$line" | awk -F'Port ' '{print $2}' | cut -d: -f1)
ANDROID_HUB="$CURRENT_HUB"
fi

if echo "$line" | grep -q "$IPHONE_VENDOR"; then
IPHONE_PORT=$(echo "$line" | awk -F'Port ' '{print $2}' | cut -d: -f1)
IPHONE_HUB="$CURRENT_HUB"
fi

done < <(uhubctl)

}

################################

get_android_battery() {
adb shell dumpsys battery 2>/dev/null | awk '/level:/ {print $2}'
}

get_iphone_battery() {
ideviceinfo -q com.apple.mobile.battery 2>/dev/null | awk '/BatteryCurrentCapacity/ {print $2}'
}

################################
# WAIT IPHONE CONNECT (NEW)
################################

wait_for_iphone() {

for i in {1..15}
do
if idevice_id -l | grep -q . ; then
return 0
fi

log "waiting iphone usb..."
sleep 2
done

return 1
}

################################
# ANDROID WORKER
################################

android_worker() {

if [ -z "$ANDROID_PORT" ]; then
log "Android not detected"
return
fi

BAT=$(get_android_battery)

log "Android battery=$BAT%"

if [ -n "$BAT" ] && [ "$BAT" -lt "$MIN_BAT" ]; then

log "Android charging start"

while true
do
BAT=$(get_android_battery)

[ -z "$BAT" ] && break

log "Android charging $BAT%"

[ "$BAT" -ge "$MAX_BAT" ] && break

sleep 60
done

log "Android charging complete"

fi

uhubctl -l "$ANDROID_HUB" -p "$ANDROID_PORT" -a off >/dev/null
log "Android power off"

}

################################
# IPHONE WORKER
################################

iphone_worker() {

if [ -z "$IPHONE_PORT" ]; then
log "iPhone not detected"
return
fi

if ! wait_for_iphone ; then
log "iPhone not detected by usbmuxd"
return
fi

BAT=""

for i in {1..10}
do
BAT=$(get_iphone_battery)
[ -n "$BAT" ] && break
log "waiting iphone battery..."
sleep 2
done

log "iPhone battery=$BAT%"

if [ -z "$BAT" ]; then
log "iPhone battery unreadable yet, keep power ON"
return
fi

if [ -n "$BAT" ] && [ "$BAT" -lt "$MIN_BAT" ]; then

log "iPhone charging start"

while true
do
BAT=$(get_iphone_battery)

[ -z "$BAT" ] && break

log "iPhone charging $BAT%"

[ "$BAT" -ge "$MAX_BAT" ] && break

sleep 60
done

log "iPhone charging complete"

fi

uhubctl -l "$IPHONE_HUB" -p "$IPHONE_PORT" -a off >/dev/null
log "iPhone power off"

}

################################

main_loop() {

while true
do

log "Powering USB hubs ON"

power_on_hubs

# IMPORTANT FIX FOR IPHONE
systemctl restart usbmuxd >/dev/null 2>&1

sleep 20

detect_ports

android_worker &
iphone_worker &

wait

log "Sleeping $CHECK_INTERVAL seconds"

sleep "$CHECK_INTERVAL"

done
}

################################

log "Controller started"

adb start-server >/dev/null 2>&1
systemctl restart usbmuxd >/dev/null 2>&1

main_loop

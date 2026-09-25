#!/system/bin/sh
# Device spot-checks: Wi-Fi state, thermal trips, loaded wifi driver
echo "=== 1. net interfaces ==="
ls /sys/class/net 2>/dev/null

echo
echo "=== 2. dmesg: dhd/bcmdhd/wlan/firmware ==="
dmesg | grep -iE "dhd|bcmdhd|wlan|fw_bcm|firmware.*439|pcie.*wlan" | tail -30

echo
echo "=== 3. blocklist sources for bcmdhd4398 ==="
ls -l /vendor/etc/init/*wifi* /vendor/etc/init/*wlan* 2>/dev/null
grep -rl "bcmdhd4398" /vendor/etc/init /system/etc/init /data/adb 2>/dev/null | head -5

echo
echo "=== 4. module state ==="
cat /proc/modules | grep -iE "bcmdhd|wlan" | head -5
ls -l /vendor/lib/modules/ 2>/dev/null | grep -iE "bcmdhd|wlan" | head -5

echo
echo "=== 5. wifi hal / service ==="
getprop | grep -iE "wifi|wlan" | grep -viE "persist.sys.wifi.*scan" | head -15

echo
echo "=== 6. thermal zones + trips ==="
for z in /sys/class/thermal/thermal_zone*; do
    t=$(cat "$z/type" 2>/dev/null)
    echo "-- $z ($t)"
    i=0
    while [ -f "$z/trip_point_${i}_temp" ]; do
        echo "   trip$i: $(cat "$z/trip_point_${i}_temp" 2>/dev/null) mode=$(cat "$z/trip_point_${i}_mode" 2>/dev/null)"
        i=$((i+1))
        [ $i -gt 6 ] && break
    done
done

echo
echo "=== 7. wifi power save current setting (if iface exists) ==="
for i in wlan0 wlan1; do
    if [ -d "/sys/class/net/$i" ]; then
        echo "$i: psmode=$(cat /sys/class/net/$i/queues/tx-0/byte_queue_limits/limit_min 2>/dev/null)"
    fi
done

echo
echo "=== DONE ==="

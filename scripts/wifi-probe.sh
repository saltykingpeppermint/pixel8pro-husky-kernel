#!/system/bin/sh
echo "=== 1. blocklist files (vendor_dlkm modules) ==="
find /vendor /system /odm -name "*blocklist*" -o -name "modules.load*" 2>/dev/null | head -10

echo
echo "=== 2. grep bcmdhd in them ==="
for f in $(find /vendor /system /odm -name "*blocklist*" -o -name "modules.load*" 2>/dev/null); do
    echo "-- $f"
    grep -iE "bcmdhd|wlan" "$f" 2>/dev/null
done

echo
echo "=== 3. /proc/modules wifi ==="
grep -iE "bcmdhd|dhd|wlan" /proc/modules

echo
echo "=== 4. wifi-related vendor libs ==="
ls /vendor/lib/modules/ 2>/dev/null | grep -iE "bcmdhd|wlan|dhd"

echo
echo "=== 5. boot dmesg from ksu log (persisted) ==="
grep -iE "dhd_bus_register|bcmdhd|dhd_probe|firmware" /data/adb/ksu/log/dmesg.log 2>/dev/null | head -20

echo
echo "=== 6. all dhd lines in rolled dmesg ==="
dmesg | grep -iE "dhd|bcmdhd|wlan0|4398" | head -20

echo
echo "=== 7. wifi status props ==="
getprop | grep -iE "vendor.wifi|wifi.driver|wlan.driver" | head -10
dumpsys wifi 2>/dev/null | head -5

echo
echo "=== DONE ==="

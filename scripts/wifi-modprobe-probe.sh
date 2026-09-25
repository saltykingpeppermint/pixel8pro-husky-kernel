#!/system/bin/sh
echo "=== 1. module control files in vendor_dlkm ==="
find /vendor_dlkm -name "modules*" -type f 2>/dev/null | head -10

echo
echo "=== 2. content of load/blocklist files ==="
for f in $(find /vendor_dlkm -name "modules.load" -o -name "modules.blocklist" -o -name "modules.load.recovery" 2>/dev/null); do
    echo "-- $f"
    grep -iE "bcmdhd|wlan|cfg80211" "$f" 2>/dev/null || echo "   (no wifi match)"
done

echo
echo "=== 3. manual modprobe attempt (fresh dmesg) ==="
dmesg -c >/dev/null 2>&1
modprobe bcmdhd4398 2>&1; echo "modprobe exit=$?"
sleep 3
echo "-- modules:"; grep -iE "bcmdhd|cfg80211" /proc/modules
echo "-- dmesg:"; dmesg | tail -30

echo
echo "=== 4. if loaded: iface + firmware path ==="
ls /sys/class/net 2>/dev/null | grep -iE "wlan|p2p"
ls -l /sys/module/bcmdhd4398 2>/dev/null | head -3

echo
echo "=== 5. wifi HAL retry after manual load ==="
svc wifi disable
sleep 2
svc wifi enable
sleep 8
ls /sys/class/net | grep -iE "wlan" || echo "(still no wlan0)"
logcat -d -t 300 2>/dev/null | grep -iE "driver ready|dhd_|bcmdhd|Timed out" | tail -10

echo
echo "=== DONE ==="

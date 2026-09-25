#!/system/bin/sh
echo "=== 1. is ksu dmesg.log current boot? (compare first/last lines) ==="
head -2 /data/adb/ksu/log/dmesg.log 2>/dev/null | cut -c1-80
tail -1 /data/adb/ksu/log/dmesg.log 2>/dev/null | cut -c1-100
echo "current uptime:"; cut -d' ' -f1 /proc/uptime
echo "crc-mismatch lines in dmesg.log:"
grep -c "disagrees about version" /data/adb/ksu/log/dmesg.log 2>/dev/null
echo "crc-mismatch in CURRENT dmesg:"
dmesg | grep -c "disagrees about version"

echo
echo "=== 2. dlkm mounts + blocklist anywhere ==="
mount | grep -iE "dlkm"
find /vendor_dlkm /system_dlkm /odm_dlkm -maxdepth 3 \( -name "*blocklist*" -o -name "modules.load*" \) 2>/dev/null | head -10

echo
echo "=== 3. cfg80211/bcmdhd .ko present? ==="
find /vendor_dlkm /system_dlkm /odm_dlkm /vendor -name "*bcmdhd*" -o -name "cfg80211*" 2>/dev/null | head -10

echo
echo "=== 4. wifi enable + watch driver ==="
dmesg -c >/dev/null 2>&1
svc wifi enable
sleep 6
echo "-- wlan iface:"; ls /sys/class/net | grep -iE "wlan|p2p" || echo "(none)"
echo "-- modules:"; grep -iE "bcmdhd|cfg80211|dhd" /proc/modules || echo "(none)"
echo "-- dmesg since clear:"; dmesg | grep -iE "dhd|bcmdhd|cfg80211|wlan|4398|firmware" | head -40

echo
echo "=== 5. wifi state ==="
dumpsys wifi 2>/dev/null | head -8

echo
echo "=== DONE ==="

#!/system/bin/sh
MODDIR=/vendor_dlkm/lib/modules/6.1.124-android14-11-g51d090c67d6e
KO="$MODDIR/extra/private/google-modules/wlan/bcm4398/bcmdhd4398.ko"

echo "=== 1. manual insmod (fresh dmesg) ==="
dmesg -c >/dev/null 2>&1
insmod "$KO" 2>&1; echo "insmod exit=$?"
sleep 4
echo "-- modules:"; grep -iE "bcmdhd|cfg80211" /proc/modules
echo "-- iface:"; ls /sys/class/net | grep -iE "wlan|p2p" || echo "(none)"
echo "-- dmesg:"
dmesg | grep -viE "bcmbtlinux|servicemanager|nitrous|libprocessgroup|flags_health|KernelSU: hook|init:" | tail -35

echo
echo "=== 2. if failed: dhd-specific lines verbatim ==="
dmesg | grep -iE "dhd|bcmdhd|wlan|firmware|pcie" | head -25

echo
echo "=== 3. BT service state (same chip) ==="
getprop init.svc.vendor.bluetooth | head -1
logcat -d -t 400 2>/dev/null | grep -iE "bcmbtlinux|Bluetooth.*fail|hci.*fail|firmware" | tail -12

echo
echo "=== DONE ==="

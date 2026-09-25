#!/system/bin/sh
echo "=== 0. root? ==="
id

echo
echo "=== 1. wifi_on setting ==="
settings get global wifi_on

echo
echo "=== 2. fresh dmesg clear + enable wifi ==="
dmesg -c >/dev/null 2>&1 && echo "cleared" || echo "clear FAILED (not root?)"
svc wifi enable
sleep 12

echo "-- net:"; ls /sys/class/net | grep -iE "wlan|p2p" || echo "(no wlan)"
echo "-- modules:"; grep -iE "bcmdhd|cfg80211" /proc/modules || echo "(cfg80211 gone)"
echo "-- full dmesg tail:"; dmesg | tail -40

echo
echo "=== 3. logcat wifi errors ==="
logcat -d -t 600 2>/dev/null | grep -iE "wifi.*(error|fail|driver|firmware)|bcmdhd|dhd_|WifiHAL|loadKernel|insmod" | tail -30

echo
echo "=== 4. who loads bcmdhd4398 (rc/modprobe) ==="
grep -rn "bcmdhd\|insmod\|modprobe" /vendor/etc/init/ 2>/dev/null | head -10
ls /vendor/etc/init/ | head -30

echo
echo "=== 5. dumpsys wifi (30 lines) ==="
dumpsys wifi 2>/dev/null | sed -n '1,30p'

echo
echo "=== DONE ==="

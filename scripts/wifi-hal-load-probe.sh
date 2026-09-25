#!/system/bin/sh
# What does the Wi-Fi HAL actually try when enabling wifi?
logcat -c
svc wifi disable
sleep 2
svc wifi enable
sleep 10
echo "=== HAL/load related logcat ==="
logcat -d 2>/dev/null | grep -iE "wifi.*load|load.*driver|modprobe|insmod|finit|bcmdhd|dhd_|driver ready|WifiHAL|legacy_hal|nl80211" | head -40
echo
echo "=== fresh dmesg (dhd/pcie) ==="
dmesg | grep -iE "dhd|bcmdhd|exynos-pcie-rc 1312|pcie.*link" | head -25
echo
echo "=== modules now ==="
grep -iE "bcmdhd|cfg80211|wlan" /proc/modules
echo "=== DONE ==="

#!/system/bin/sh
# After reboot: did the wifi endpoint enumerate this boot?
sleep 12
echo "=== uptime ==="; cut -d' ' -f1 /proc/uptime
echo "=== result ==="
if grep -q bcmdhd4398 /proc/modules; then
    echo "MODULE LOADED"
    dmesg | grep -E "Register interface \[wlan0\]|dhd_open|Link is up|L0\(" | head -5
else
    echo "MODULE FAILED/ABSENT"
    dmesg | grep -E "No Broadcom|Link is not up, try count: 10|DETECT QUIET" | head -4
fi
echo "=== net ==="
ls /sys/class/net | grep -iE "wlan" || echo "(no wlan0)"
echo "=== DONE ==="

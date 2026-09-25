#!/system/bin/sh
OUT=/data/local/tmp/boot-dhd.txt
echo "=== uptime ==="; cut -d' ' -f1 /proc/uptime
echo "=== bcmdhd/cfg80211 loaded? ==="
grep -E "bcmdhd|cfg80211" /proc/modules || echo "(bcmdhd NOT loaded)"
echo
echo "=== net ifaces ==="
ls /sys/class/net | grep -iE "wlan|p2p" || echo "(no wlan iface)"
echo
echo "=== dmesg: dhd/probe outcome ==="
dmesg | grep -iE "dhd|bcmdhd|No Broadcom|Link is not up|dhd_bus_register|Register interface|wlan0" | head -40
echo
echo "=== dmesg: PCIe rc (wifi RC 13120000 / link) ==="
dmesg | grep -iE "13120000|pcie.*link|LTSSM" | head -15
echo
echo "=== crc mismatches in this boot ==="
dmesg | grep -c "disagrees about version"
echo
echo "=== bcmbtlinux state ==="
getprop init.svc.vendor.bluetooth 2>/dev/null
logcat -d -t 100 2>/dev/null | grep -iE "coex|bcmbtlinux" | tail -5
echo "=== DONE ==="

#!/system/bin/sh
echo "=== 1. insmod.sh configs on device ==="
ls -la /vendor_dlkm/etc/ 2>/dev/null | head -20
ls -la /vendor/etc/init.common.cfg /vendor_dlkm/etc/init.insmod.*.cfg 2>/dev/null
echo
echo "=== 2. husky cfg content (wifi lines + full if short) ==="
CFG=/vendor_dlkm/etc/init.insmod.husky.cfg
if [ -f "$CFG" ]; then
    echo "-- grep wifi:"
    grep -inE "bcmdhd|cfg80211|wlan|wifi" "$CFG"
    echo "-- total lines: $(wc -l < $CFG)"
    echo "-- head:"; head -15 "$CFG"
else
    echo "MISSING: $CFG"
fi
echo
echo "=== 3. init.common.cfg ==="
if [ -f /vendor/etc/init.common.cfg ]; then
    grep -inE "bcmdhd|cfg80211|wlan|wifi" /vendor/etc/common.cfg /vendor/etc/init.common.cfg 2>/dev/null
    echo "-- total: $(wc -l < /vendor/etc/init.common.cfg)"
else
    echo "MISSING /vendor/etc/init.common.cfg"
fi
echo
echo "=== 4. insmod.sh: does it check blocklist? (strings) ==="
strings /vendor/bin/insmod.sh 2>/dev/null | head -30
echo
echo "=== 5. init.husky.rc insmod trigger lines ==="
sed -n '1,30p' /vendor/etc/init/hw/init.husky.rc 2>/dev/null
echo "=== DONE ==="

#!/system/bin/sh
echo "=== 1. blocklisted-but-listed modules: are the CONTROLS loaded? ==="
echo "(ftm5/goodix/sec_touch/gnss_spi/rt6160/cs40l26_i2c are blocklisted AND in modules.load)"
grep -E "^(ftm5|goodix_brl_touch|sec_touch|gnss_spi|gnssif|rt6160|cs40l26_i2c|bcmdhd4398|aoc_unit_test_dev) " /proc/modules || echo "(none of them loaded)"
echo
echo "=== 2. all loaded vendor modules (count) ==="
wc -l < /proc/modules
echo
echo "=== 3. WIFI HAL binary: how does it load the driver? ==="
for b in /vendor/bin/hw/*wifi* /vendor/bin/hw/*Wifi*; do
    if [ -f "$b" ]; then
        echo "-- $b"
        strings "$b" 2>/dev/null | grep -iE "bcmdhd|modprobe|insmod|finit|modules.load|\.ko|driver ready|sys/module" | head -20
    fi
done
echo
echo "=== 4. init rc files referencing wifi/modprobe/insmod ==="
grep -rniE "bcmdhd|modprobe|insmod|finit_module" /vendor/etc/init/ /odm/etc/init/ /system/etc/init/ 2>/dev/null | head -20
echo
echo "=== 5. any 'wifi' rc file content ==="
ls -la /vendor/etc/init/ | grep -iE "wifi|wlan"
echo
echo "=== 6. module loading props ==="
getprop | grep -iE "wifi.*load|load.*module|vendor.modules" | head -10
echo "=== DONE ==="

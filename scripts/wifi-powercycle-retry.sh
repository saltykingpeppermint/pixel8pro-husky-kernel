#!/system/bin/sh
# Try to hard power-cycle the BCM4398 (WL_REG_ON=GPIO107) then reload driver
echo "=== 1. mounts for gpio/debug ==="
mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null
ls /sys/class/gpio/ 2>/dev/null | head -5 || echo "(no /sys/class/gpio)"
echo
echo "=== 2. gpio 107 state ==="
if [ -d /sys/class/gpio/gpio107 ]; then
    echo "exported: direction=$(cat /sys/class/gpio/gpio107/direction) value=$(cat /sys/class/gpio/gpio107/value)"
else
    echo 107 > /sys/class/gpio/export 2>/dev/null
    sleep 1
    if [ -d /sys/class/gpio/gpio107 ]; then
        echo "after export: direction=$(cat /sys/class/gpio/gpio107/direction) value=$(cat /sys/class/gpio/gpio107/value)"
    else
        echo "export failed (CONFIG_GPIO_SYSFS off?)"
    fi
fi
echo
echo "=== 3. pinctrl pin 107 ==="
grep -E "^\s*\*\s*107\)|\(107\)" /sys/kernel/debug/pinctrl/*/pinmux-pins 2>/dev/null | head -3
grep -E "107" /sys/kernel/debug/pinctrl/*/pinconf-pins 2>/dev/null | head -3
echo
echo "=== 4. power cycle attempt ==="
if [ -d /sys/class/gpio/gpio107 ]; then
    echo out > /sys/class/gpio/gpio107/direction 2>/dev/null
    echo 0 > /sys/class/gpio/gpio107/value
    echo "dropped WL_REG_ON: $(cat /sys/class/gpio/gpio107/value)"
    sleep 2
    echo 1 > /sys/class/gpio/gpio107/value
    echo "raised WL_REG_ON: $(cat /sys/class/gpio/gpio107/value)"
    sleep 1
    echo "=== 5. reload driver ==="
    KDIR=/vendor_dlkm/lib/modules/$(uname -r)
    insmod "$KDIR/extra/private/google-modules/wlan/bcm4398/bcmdhd4398.ko" 2>&1
    echo "insmod rc=$?"
    sleep 4
    dmesg | grep -E "dhd|Link is not up|No Broadcom|Register interface|LTSSM:" | tail -20
    echo
    ls /sys/class/net | grep -i wlan || echo "(still no wlan)"
else
    echo "no gpio sysfs - cannot power cycle from userspace"
fi
echo "=== DONE ==="

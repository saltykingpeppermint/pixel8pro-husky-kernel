#!/system/bin/sh
echo "=== 1. ALL PCIe ch1 (wifi RC 13120000) lines from boot ==="
dmesg | grep -E "13120000|exynos_pcie" | head -60
echo
echo "=== 2. PCIe lines in 5.0-8.0s window (link training attempt) ==="
dmesg | awk '{ts=$1; gsub(/[\[\]]/,"",ts); if (ts+0 >= 5.0 && ts+0 <= 8.5) print}' | grep -iE "pcie|ltssm|perst|refclk|phy" | head -40
echo
echo "=== 3. BT side of combo chip: service + errors ==="
getprop | grep -E "init.svc.*(bluetooth|bt)" | head -5
logcat -d -b all 2>/dev/null | grep -iE "bcmbtlinux|btusb|hci|brcm" | grep -vE "coex_device|DeviceOpen" | tail -20
echo
echo "=== 4. BT device nodes present? ==="
ls -la /dev/ttyHS* /dev/ttyUSB* 2>/dev/null
ls /sys/bus/usb/devices/ 2>/dev/null | head -10
lsusb 2>/dev/null | head -10
echo
echo "=== 5. WL_REG_ON (GPIO 107) current state via sysfs ==="
for p in /sys/class/gpio/gpio107 /sys/kernel/debug/gpio; do ls -la $p 2>/dev/null; done
cat /sys/kernel/debug/gpio 2>/dev/null | grep -iE "107|wlan|reg_on" | head -5
echo
echo "=== 6. wifi HAL retry now (second enable attempt) ==="
svc wifi disable 2>/dev/null; sleep 1; svc wifi enable 2>/dev/null; sleep 6
dmesg | tail -8
echo "=== DONE ==="

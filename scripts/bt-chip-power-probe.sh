#!/system/bin/sh
echo "=== 1. USB devices (BCM4398 BT = Broadcom 0a5c on USB) ==="
for d in /sys/bus/usb/devices/*/; do
    if [ -f "$d/idVendor" ]; then
        echo "$d $(cat $d/idVendor):$(cat $d/idProduct) $(cat $d/manufacturer 2>/dev/null) $(cat $d/product 2>/dev/null)"
    fi
done
echo
echo "=== 2. /dev/bus/usb ==="
ls -la /dev/bus/usb/*/* 2>/dev/null | head -10
echo
echo "=== 3. tty/serial devices ==="
ls /dev/tty* 2>/dev/null | tr ' ' '\n' | grep -E "HS|USB|SAC|APP" | head -10
echo
echo "=== 4. bcmbtlinux transport result (logcat) ==="
logcat -d -b all 2>/dev/null | grep -iE "bcmbtlinux|bthal" | grep -iE "fail|error|open|usb|tty|firmware|hci" | tail -15
echo
echo "=== 5. rfkill state ==="
cat /sys/class/rfkill/*/state 2>/dev/null | head -5
ls /sys/class/rfkill/ 2>/dev/null
echo "=== DONE ==="

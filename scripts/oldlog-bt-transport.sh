#!/bin/bash
OK="/mnt/c/Users/King/Documents/Default Project/out/dmesg-ksu-log.log"       # Sept18 SUCCESS
F="/mnt/c/Users/King/Documents/Default Project/out/dmesg-ksu-log-old.log"   # Sept18 FAILURE

for pair in "SUCCESS:$OK" "FAILURE:$F"; do
    label="${pair%%:*}"; file="${pair#*:}"
    echo "################ $label ################"
    echo "-- USB enumeration lines:"
    grep -iE "usb [0-9]+-[0-9]+: .*Broadcom|btusb|new .*USB device|Product: BCM|idVendor" "$file" | head -8
    echo "-- BT transport / hci:"
    grep -iE "hci0|ttyHS|hci_uart|firmware:.*BCM4|bluetooth.*firmware|bcm4398" "$file" | head -8
    echo "-- chip power clues (regulator/wlan):"
    grep -iE "wlan.*reg|reg.*wlan|WL_REG|vdd.*wlan|pinctrl.*107" "$file" | head -6
    echo
done
echo "=== DONE ==="

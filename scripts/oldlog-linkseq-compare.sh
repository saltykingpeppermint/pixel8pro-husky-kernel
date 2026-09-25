#!/bin/bash
# Extract the FULL link-training sequence from historical success vs failure boots
P="/mnt/c/Users/King/Documents/Default Project/out"
OK="$P/dmesg-ksu-log.log"        # historical boot where wlan0 registered (success)
FAIL="$P/dmesg-ksu-log-old.log"  # historical boot with No Broadcom PCI device (failure)

echo "################ HISTORICAL SUCCESS ($OK) ################"
echo "-- module init + link sequence (context around _dhd_module_init in):"
L=$(grep -n "_dhd_module_init in" "$OK" | head -1 | cut -d: -f1)
if [ -n "$L" ]; then
    sed -n "$((L)),$((L+120))p" "$OK" | grep -E "dhd|pcie|Link|LTSSM|PERST|refclk|Regulator|regulator|Broadcom" | head -40
fi
echo
echo "-- any 'Link is up' lines in whole file:"
grep -cE "Link is up|link up|LTSSM.*(L0|exit)" "$OK"
grep -E "Link is up|link up success" "$OK" | head -5
echo
echo "-- BT in success boot:"
grep -nE "bcmbtlinux|hci0|Bluetooth.*ready|btusb" "$OK" | head -8
echo
echo "################ HISTORICAL FAILURE ($FAIL) ################"
L=$(grep -n "_dhd_module_init in" "$FAIL" | head -1 | cut -d: -f1)
if [ -n "$L" ]; then
    sed -n "$((L)),$((L+140))p" "$FAIL" | grep -E "dhd|pcie|Link|LTSSM|PERST|refclk|Regulator|regulator|Broadcom" | head -40
fi
echo
echo "-- any 'Link is up' lines:"
grep -cE "Link is up|link up" "$FAIL"
echo
echo "-- BT in failure boot:"
grep -nE "bcmbtlinux|hci0|Bluetooth.*ready" "$FAIL" | head -8
echo
echo "=== temperature/voltage clues near failure (failure boot) ==="
grep -iE "throttl|undervolt|vdd_pcie|pwr.*off" "$FAIL" | head -5
echo "=== DONE ==="

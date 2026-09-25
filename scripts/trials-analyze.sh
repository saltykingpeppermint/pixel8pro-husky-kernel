#!/bin/bash
# Analyze the 3 reboot-trial dmesg logs for wifi enum verdict
P="/mnt/c/Users/King/Documents/Default Project/out"
for i in 1 2 3; do
    F="$P/dmesg-trial-$i.log"
    echo "################ trial $i ################"
    [ -f "$F" ] || { echo "missing $F"; continue; }
    echo "-- kernel: $(grep -a -m1 'Linux version' "$F" | head -c 160)"
    echo "-- dhd init: $(grep -ac '_dhd_module_init in' "$F")"
    echo "-- DETECT QUIET tries: $(grep -ac 'DETECT QUIET' "$F")"
    echo "-- verdict lines:"
    grep -aE 'No Broadcom PCI device|Register interface \[wlan0\]|dhd_bus_register failed|module bcmdhd4398 is blocklisted|LoadWithAliases was unable' "$F" | head -6
    echo "-- pcie link outcome:"
    grep -aE 'L0\(|link is up|link up' "$F" | head -3
    echo
done
echo "=== DONE ==="

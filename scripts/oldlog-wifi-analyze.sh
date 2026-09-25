#!/bin/bash
# Did the Wi-Fi chip (BCM4398, PCIe endpoint) EVER enumerate on this phone?
set -u
P="/mnt/c/Users/King/Documents/Default Project/out"

for f in "$P/dmesg-ksu-log.log" "$P/dmesg-ksu-log-old.log"; do
    echo "################ $(basename $f) ################"
    echo "-- kernel version:"
    grep -m1 "Linux version" "$f" | cut -c1-110

    echo "-- module CRC mismatches (count):"
    grep -c "disagrees about version" "$f"

    echo "-- dhd probe outcome lines:"
    grep -nE "dhd_bus_register|No Broadcom PCI|Link is not up|_dhd_module_init|Register interface" "$f" | head -20

    echo "-- PCIe link state around wifi (exynos rc lines):"
    grep -nE "exynos.*pcie.*(link up|Link up|enumerat|LTSSM|link up fail)|pcie link up fail" "$f" | head -10

    echo "-- did wlan0 ever get opened / scan:"
    grep -nE "dhd_open|wl_cfgvendor_set_hal_started|wlan0" "$f" | head -8

    echo "-- BT (same combo chip) status:"
    grep -nE "bcmbtlinux|hci.*down|firmware.*fail|coex" "$f" | head -8
    echo
done
echo "=== DONE ==="

#!/system/bin/sh
echo "=== modem PCIe RC (ch0 = 12100000) link state ==="
dmesg | grep -E "12100000" | grep -iE "link|L0|up|enumerat" | head -8
echo
echo "=== all pcieport buses (endpoints that DID enumerate) ==="
ls /sys/bus/pci/devices/ 2>/dev/null
echo
echo "=== pci devices detail ==="
for d in /sys/bus/pci/devices/*; do
    if [ -f "$d/vendor" ]; then
        echo "$d $(cat $d/vendor):$(cat $d/device) $(cat $d/class)"
    fi
done
echo
echo "=== modem function (radio) ==="
getprop gsm.network.type
getprop gsm.sim.state
echo "=== DONE ==="

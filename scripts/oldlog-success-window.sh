#!/bin/bash
# Full window: _dhd_module_init in -> _dhd_module_init out for SUCCESS log
OK="/mnt/c/Users/King/Documents/Default Project/out/dmesg-ksu-log.log"
A=$(grep -n "_dhd_module_init in" "$OK" | head -1 | cut -d: -f1)
B=$(grep -n "_dhd_module_init out" "$OK" | head -1 | cut -d: -f1)
echo "success window: lines $A-$B"
sed -n "${A},${B}p" "$OK" | grep -E "pcie|Link|LTSSM|PERST|Broadcom|dhd_bus|Register|link" | head -50
echo
echo "=== counts in window ==="
sed -n "${A},${B}p" "$OK" | grep -cE "Link is not up"
sed -n "${A},${B}p" "$OK" | grep -cE "Set PERST"
echo
echo "=== failure log window (old) ==="
F="/mnt/c/Users/King/Documents/Default Project/out/dmesg-ksu-log-old.log"
A=$(grep -n "_dhd_module_init in" "$F" | head -1 | cut -d: -f1)
B=$(grep -n "_dhd_module_init out" "$F" | head -1 | cut -d: -f1)
echo "failure window: lines $A-$B"
sed -n "${A},${B}p" "$F" | grep -E "Set PERST|Link is not up|LTSSM:|No Broadcom|dhd_bus_register" | head -25
echo "=== DONE ==="

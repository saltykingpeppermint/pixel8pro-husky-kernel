#!/bin/bash
export PATH="/home/king/kernel-shusky/prebuilts/kernel-build-tools/linux-x86/bin:$PATH"
OUT=/tmp/dtbo-cmp/dts
echo "=== diff dtb1 stock vs ours ==="
diff "$OUT/stock/dtb1.dts" "$OUT/ours/dtb1.dts"
echo
echo "=== diff dtb0 ==="
diff "$OUT/stock/dtb0.dts" "$OUT/ours/dtb0.dts"
echo
echo "=== what are these blobs? model/compatible ==="
for f in "$OUT/ours"/dtb0.dts "$OUT/ours"/dtb1.dts; do
    echo "--- $f"
    grep -m3 -E 'model|compatible' "$f"
done
echo
echo "=== any thermal content in ours? ==="
grep -l 'thermal' "$OUT/ours"/*.dts | head
grep -m5 'trip' "$OUT/ours/dtb1.dts"
echo
echo "=== search '13120000' or 'pcie' anywhere ==="
grep -l 'pcie' "$OUT/ours"/*.dts | head -5
grep -m3 '13120000' "$OUT/ours"/*.dts | head
echo "=== DONE ==="

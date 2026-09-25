#!/bin/bash
export PATH="/home/king/kernel-shusky/prebuilts/kernel-build-tools/linux-x86/bin:$PATH"
OUT=/tmp/dtbo-cmp/dts

echo "=== trip blocks in ours dtb1 (with temps) ==="
awk '/trips \{/{p=1; d=0} p {print; n=gsub(/{/,"{"); m=gsub(/}/,"}"); d+=n-m; if (d<=0 && /}/) {p=0; print "----"}}' "$OUT/ours/dtb1.dts" | head -60

echo
echo "=== 'control_temp' / trip temps anywhere in ours ==="
grep -rn 'control_temp' "$OUT/ours"/*.dts | head -10
grep -rn '85000\|0x14c08' "$OUT/ours"/*.dts | head -10

echo
echo "=== pcie nodes in ours (node names) ==="
grep -rhn 'pcie[a-z0-9@, -]*{' "$OUT/ours"/*.dts | sort -u | head -20

echo
echo "=== which blob is the base SoC dtb? (has /soc with exynos-pcie) ==="
grep -l 'exynos-pcie\|13120000\|12100000' "$OUT/ours"/*.dts | head
grep -rl 'zuma' "$OUT/ours"/*.dts | head -5

echo "=== DONE ==="

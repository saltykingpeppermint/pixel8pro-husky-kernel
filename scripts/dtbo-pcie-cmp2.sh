#!/bin/bash
export PATH="/home/king/kernel-shusky/prebuilts/kernel-build-tools/linux-x86/bin:$PATH"
WORK=/tmp/dtbo-cmp
OUT=/tmp/dtbo-cmp/dts
mkdir -p "$OUT/ours" "$OUT/stock"
for tag in ours stock; do
    for f in "$WORK/$tag"/dtb*.dtb; do
        b=$(basename "$f" .dtb)
        dtc -q -I dtb -O dts "$f" > "$OUT/$tag/$b.dts" 2>/dev/null || echo "dtc FAIL: $f"
    done
done
echo "decompiled: $(ls "$OUT/ours" | wc -l) ours, $(ls "$OUT/stock" | wc -l) stock"

echo
echo "=== which dtbs contain the wifi RC (13120000) ==="
grep -l '13120000' "$OUT/ours"/*.dts | head; echo "--- stock:"; grep -l '13120000' "$OUT/stock"/*.dts | head

echo
echo "=== wifi RC node: ours vs stock (first match each) ==="
OURS_F=$(grep -l '13120000' "$OUT/ours"/*.dts | head -1)
STOCK_F=$(grep -l '13120000' "$OUT/stock"/*.dts | head -1)
echo "ours=$OURS_F stock=$STOCK_F"
if [ -n "$OURS_F" ] && [ -n "$STOCK_F" ]; then
    for f in "$OURS_F" "$STOCK_F"; do
        awk '/13120000/ && /\{/ {p=1; d=0} p {print; n=gsub(/{/,"{"); m=gsub(/}/,"}"); d+=n-m; if (d<=0 && /}/) exit}' "$f"
        echo "########"
    done > "$WORK/rc-nodes.txt"
    # split into two files for diff: count ########
    awk 'BEGIN{n=1} /^########$/{n++; next} {print > ("/tmp/dtbo-cmp/rc-" n ".dts")}' "$WORK/rc-nodes.txt"
    echo "--- diff (stock=rc-1 < | ours=rc-2 >):"
    diff /tmp/dtbo-cmp/rc-1.dts /tmp/dtbo-cmp/rc-2.dts && echo "(wifi RC node IDENTICAL)"
fi

echo
echo "=== our patched trips in our dtbs (control_temp context) ==="
grep -rn -A3 'control_temp' "$OUT/ours"/*.dts | grep -E 'dts[:-].*(control_temp|temperature)' | sed 's|.*/||' | sort -u | head -40

echo
echo "=== stock trips (control_temp context) ==="
grep -rn -A3 'control_temp' "$OUT/stock"/*.dts | grep -E 'dts[:-].*(control_temp|temperature)' | sed 's|.*/||' | sort -u | head -40

echo
echo "=== trip temps diff summary: stock vs ours (whole files) ==="
for f in "$OUT/ours"/*.dts; do
    b=$(basename "$f")
    s="$OUT/stock/$b"
    if [ -f "$s" ]; then
        n=$(diff "$s" "$f" | grep -cE '^[<>]')
        t=$(diff "$s" "$f" | grep -E '^[<>]' | grep -E 'temperature|trip' | head -8)
        echo "--- $b : $n diff lines"
        [ -n "$t" ] && echo "$t"
    fi
done
echo "=== DONE ==="

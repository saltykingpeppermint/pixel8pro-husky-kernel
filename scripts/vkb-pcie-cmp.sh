#!/bin/bash
export PATH="/home/king/kernel-shusky/prebuilts/kernel-build-tools/linux-x86/bin:$PATH"
P="/mnt/c/Users/King/Documents/Default Project"
PARSER="$P/scripts/parse-trips.py"
STOCK="/mnt/d/pixel8pro-factory/out/husky_beta-bp31.250610.009"

echo "=== 1) parse-trips.py on our out/dtbo.img ==="
python3 "$PARSER" "$P/out/dtbo.img" 2>&1 | sort | uniq -c | sort -rn | head -20
echo "total lines: $(python3 "$PARSER" "$P/out/dtbo.img" 2>/dev/null | wc -l)"

echo
echo "=== 2) raw grep for wifi RC 13120000 in images (binary) ==="
for f in "$P/out/dtbo.img" "$STOCK/dtbo.img" "$P/out/vendor_kernel_boot.img" "$STOCK/vendor_kernel_boot.img"; do
    [ -f "$f" ] || { echo "missing $f"; continue; }
    c=$(grep -ac '13120000' "$f" 2>/dev/null || true)
    # binary grep: use grep -a -c on decoded strings
    s=$(strings -a "$f" | grep -c '13120000' || true)
    echo "$(basename $(dirname "$f"))/$(basename "$f"): strings-match=$s"
done

echo
echo "=== 3) unpack our + stock vendor_kernel_boot dtb, compare wifi RC node ==="
rm -rf /tmp/vkb-cmp && mkdir -p /tmp/vkb-cmp/ours /tmp/vkb-cmp/stock
python3 /home/king/kernel-shusky/tools/mkbootimg/unpack_bootimg.py --boot_img "$P/out/vendor_kernel_boot.img" --out /tmp/vkb-cmp/ours >/dev/null 2>&1 && echo "ours unpacked: $(ls /tmp/vkb-cmp/ours)"
python3 /home/king/kernel-shusky/tools/mkbootimg/unpack_bootimg.py --boot_img "$STOCK/vendor_kernel_boot.img" --out /tmp/vkb-cmp/stock >/dev/null 2>&1 && echo "stock unpacked: $(ls /tmp/vkb-cmp/stock)"

for tag in ours stock; do
    if [ -f "/tmp/vkb-cmp/$tag/dtb" ]; then
        dtc -q -I dtb -O dts "/tmp/vkb-cmp/$tag/dtb" > "/tmp/vkb-cmp/$tag.dts" 2>/dev/null
        echo "--- $tag dtb decompiled: $(wc -l < /tmp/vkb-cmp/$tag.dts) lines"
        echo "    has 13120000: $(grep -c '13120000' /tmp/vkb-cmp/$tag.dts)"
        echo "    has control-temp: $(grep -c 'control-temp\|control_temp' /tmp/vkb-cmp/$tag.dts)"
        echo "    trips:"; python3 "$PARSER" "/tmp/vkb-cmp/$tag/dtb" 2>/dev/null | sort -u | head -20
    fi
done

echo
echo "=== 4) wifi RC node diff (stock < | ours >) ==="
if [ -f /tmp/vkb-cmp/ours.dts ] && [ -f /tmp/vkb-cmp/stock.dts ]; then
    for f in /tmp/vkb-cmp/stock.dts /tmp/vkb-cmp/ours.dts; do
        awk '/13120000/ && /\{/ {p=1; d=0} p {print; n=gsub(/{/,"{"); m=gsub(/}/,"}"); d+=n-m; if (d<=0 && /}/) exit}' "$f"
        echo "##########"
    done > /tmp/vkb-cmp/rc.txt
    awk 'BEGIN{n=1} /^##########$/{n++; next} {print > ("/tmp/vkb-cmp/rc-" n ".dts")}' /tmp/vkb-cmp/rc.txt
    diff /tmp/vkb-cmp/rc-1.dts /tmp/vkb-cmp/rc-2.dts && echo "(wifi RC node IDENTICAL)"
    echo "--- stock rc node:"; cat /tmp/vkb-cmp/rc-1.dts
fi
echo "=== DONE ==="

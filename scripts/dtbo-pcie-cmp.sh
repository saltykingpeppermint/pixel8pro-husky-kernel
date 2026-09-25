#!/bin/bash
# 1) Control trips of our dtbo DTBs (proper FDT property names)
# 2) Diff pcie@13120000 (wifi RC ch1) node: stock dtbo vs our dtbo
export PATH="/home/king/kernel-shusky/prebuilts/kernel-build-tools/linux-x86/bin:$PATH"
OURS="/mnt/c/Users/King/Documents/Default Project/out/dtbo.img"
STOCK="/mnt/d/pixel8pro-factory/out/husky_beta-bp31.250610.009/dtbo.img"
WORK=/tmp/dtbo-cmp
rm -rf "$WORK"; mkdir -p "$WORK/ours" "$WORK/stock"

python3 - "$OURS" "$WORK/ours" <<'EOF'
import struct, sys
src, outdir = sys.argv[1], sys.argv[2]
data = open(src,"rb").read()
magic = b"\xd0\x0d\xfe\xed"
i = data.find(magic); n = 0
while i != -1:
    totalsize = struct.unpack(">I", data[i+4:i+8])[0]
    if 1024 <= totalsize <= len(data) - i:   # sanity
        open(f"{outdir}/dtb{n}.dtb","wb").write(data[i:i+totalsize])
        n += 1
        i = data.find(magic, i+totalsize)
    else:
        i = data.find(magic, i+1)
print(f"{src}: extracted {n} blobs")
EOF
python3 - "$STOCK" "$WORK/stock" <<'EOF'
import struct, sys
src, outdir = sys.argv[1], sys.argv[2]
data = open(src,"rb").read()
magic = b"\xd0\x0d\xfe\xed"
i = data.find(magic); n = 0
while i != -1:
    totalsize = struct.unpack(">I", data[i+4:i+8])[0]
    if 1024 <= totalsize <= len(data) - i:
        open(f"{outdir}/dtb{n}.dtb","wb").write(data[i:i+totalsize])
        n += 1
        i = data.find(magic, i+totalsize)
    else:
        i = data.find(magic, i+1)
print(f"{src}: extracted {n} blobs")
EOF

echo
echo "############ 1) trips: our dtbs (BIG/MID/LITTLE/G3D control) ############"
for f in "$WORK/ours"/dtb*.dtb; do
    dts=$(dtc -q -I dtb -O dts "$f" 2>/dev/null) || continue
    # only cpu/gpu thermal nodes
    hits=$(echo "$dts" | grep -B2 -A4 'temperature' | grep -E 'temperature|type =' | tr -d ' ;' | paste -sd' ' -)
    name=$(echo "$dts" | grep -m1 'model' | head -1)
    cpuhits=$(echo "$dts" | awk '/thermal-zones|cpu-thermal|gpu-thermal/{p=1} p&&/temperature/{print}' | head -8)
    if echo "$dts" | grep -q 'control_temp\|trip-point\|critical'; then
        echo "--- $f"
        echo "$dts" | grep -E 'temperature =|type =' | sed 's/^ *//' | head -40
    fi
done

echo
echo "############ 2) pcie@13120000 node: ours vs stock ############"
find_pcie_dtb() {
    local dir="$1"
    for f in "$dir"/dtb*.dtb; do
        if dtc -q -I dtb -O dts "$f" 2>/dev/null | grep -q '13120000.pcie\|pcie@13120000'; then
            echo "$f"
        fi
    done
}
for tag in ours stock; do
    echo "=== $tag pcie dtbs ==="
    find_pcie_dtb "$WORK/$tag"
done > "$WORK/pcie-list.txt"
cat "$WORK/pcie-list.txt"

# dump & normalize the pcie node from the first matching dtb of each
dump_node() {
    local f="$1"
    dtc -q -I dtb -O dts "$f" 2>/dev/null | awk '
      /pcie@13120000/ {p=1; depth=0}
      p {
        print
        n=gsub(/\{/,"{"); m=gsub(/\}/,"}")
        depth += n - m
        if (depth <= 0 && /\}/) exit
      }'
}
O=$(find_pcie_dtb "$WORK/ours" | head -1)
S=$(find_pcie_dtb "$WORK/stock" | head -1)
if [ -n "$O" ] && [ -n "$S" ]; then
    dump_node "$O" > "$WORK/pcie-ours.dts"
    dump_node "$S" > "$WORK/pcie-stock.dts"
    echo "--- diff (stock < | ours >) ---"
    diff "$WORK/pcie-stock.dts" "$WORK/pcie-ours.dts" && echo "(pcie node IDENTICAL)"
else
    echo "missing: ours=$O stock=$S"
fi

echo
echo "############ 3) whole-DTB diff summary (stock vs ours, first pcie dtb) ############"
if [ -n "$O" ] && [ -n "$S" ]; then
    dtc -q -I dtb -O dts "$O" > "$WORK/full-ours.dts" 2>/dev/null
    dtc -q -I dtb -O dts "$S" > "$WORK/full-stock.dts" 2>/dev/null
    diff "$WORK/full-stock.dts" "$WORK/full-ours.dts" | grep -E '^[<>]' | grep -vE 'phandle|linux,phandle|status = "okay"' | head -60
    echo "--- total diff lines: $(diff "$WORK/full-stock.dts" "$WORK/full-ours.dts" | grep -cE '^[<>]')"
fi
echo "=== DONE ==="

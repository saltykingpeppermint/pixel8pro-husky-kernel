#!/bin/bash
# Split each vendor_kernel_boot dtb (ours + stock) into its concatenated FDTs,
# decompile, and extract the FULL thermal-zones trip list per zone.
# Then diff ours vs stock: expect exactly 4 changed control temps per FDT.
export PATH="/home/king/kernel-shusky/prebuilts/kernel-build-tools/linux-x86/bin:$PATH"
P="/mnt/c/Users/King/Documents/Default Project"
W=/tmp/trips-full
rm -rf "$W"; mkdir -p "$W/ours" "$W/stock"

python3 "$P/scripts/split-fdt.py" /tmp/vkb-cmp/ours/dtb "$W/ours"
python3 "$P/scripts/split-fdt.py" /tmp/vkb-cmp/stock/dtb "$W/stock"

extract_trips() {
    # $1 = dtb file -> print "zone temp type" lines in file order
    dtc -q -I dtb -O dts "$1" 2>/dev/null | awk '
        /thermal-zones/ {tz=1}
        tz && /^		[a-zA-Z0-9,_-]+-thermal/ { zone=$1; sub(/[ \t]*\{.*/,"",zone) }
        tz && /temperature =/ { temp=$3; gsub(/[<>;]/,"",temp) }
        tz && /type =/ { typ=$3; gsub(/[";]/,"",typ) }
        tz && temp!="" && typ!="" { print zone, temp, typ; temp=""; typ="" }
    '
}

for tag in ours stock; do
    for f in "$W/$tag"/fdt*.dtb; do
        [ -f "$f" ] || continue
        b=$(basename "$f" .dtb)
        extract_trips "$f" > "$W/$tag-$b.trips"
        n=$(wc -l < "$W/$tag-$b.trips")
        echo "$tag $b : $n trips"
    done
done

echo
echo "=== per-zone control trips: ours vs stock (key zones) ==="
for z in big-thermal mid-thermal little-thermal gpu-thermal; do
    echo "--- $z"
    for tag in ours stock; do
        vals=$(grep "^$z " "$W/$tag-fdt0.trips" 2>/dev/null | grep -E ' 90000 | 95000 | 85000 | 100000 ' | awk '{print $2}' | paste -sd, -)
        echo "    $tag: $vals"
    done
done

echo
echo "=== per-FDT full diff (stock < | ours >), thermal lines only ==="
for f in "$W"/ours-fdt*.trips; do
    b=$(basename "$f" .trips)
    b=${b#ours-}
    s="$W/stock-$b.trips"
    [ -f "$s" ] || { echo "$b: missing stock"; continue; }
    echo "--- $b"
    if diff "$s" "$f" > "$W/diff-$b.txt" 2>&1; then
        echo "    (identical)"
    else
        grep -E '^[<>]' "$W/diff-$b.txt" | sed 's/^/    /'
    fi
done
echo "=== DONE ==="

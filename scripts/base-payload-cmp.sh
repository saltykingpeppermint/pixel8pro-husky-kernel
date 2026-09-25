#!/bin/bash
# Compare the UNPACKED payloads (kernel/ramdisk/metadata) of the two boot
# bases to decide whether out/boot-aicp.img == out/boot-stock.img is
# legitimate (identical payloads) or a packaging bug (stale/wrong file).
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
MK="$HOME/kernel-shusky/tools/mkbootimg"

for b in aicp-boot stock-boot; do
    d=$(mktemp -d)
    echo "===== base/$b.img ====="
    python3 "$MK/unpack_bootimg.py" --boot_img "$HERE/base/$b.img" --out "$d" \
        | grep -E 'header version|os version|os patch level|command line args|page size|kernel size|ramdisk size'
    for f in kernel ramdisk bootconfig dtb; do
        if [ -f "$d/$f" ]; then
            echo "-- $f:"
            md5sum "$d/$f" | awk '{print "   md5", $1}'
            ls -la "$d/$f" | awk '{print "   size", $5}'
        fi
    done
    for r in "$d"/ramdisk*; do
        [ -e "$r" ] && [ "$r" != "$d/ramdisk" ] && { echo "-- $r:"; md5sum "$r"; }
    done
    rm -rf "$d"
done

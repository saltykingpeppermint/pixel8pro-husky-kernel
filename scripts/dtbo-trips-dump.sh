#!/bin/bash
# Dump control trips of all 4 DTBs in our built dtbo.img, compare vs device reading.
set -e
DTBO="/mnt/c/Users/King/Documents/Default Project/out/dtbo.img"
WORK="/tmp/dtbo-trips"
rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"

# dtbo.img is a mkdtimg container: use unpack_dtbo if present, else parse manually via mkdtimg/dtc
if command -v unpack_dtbo >/dev/null 2>&1; then
    unpack_dtbo "$DTBO" "$WORK"
elif command -v mkdtimg >/dev/null 2>&1; then
    mkdtimg dump "$DTBO" | head -40
fi

# Fallback: carve DTBs out by FDT magic
python3 - <<'EOF'
import struct, os, glob
data = open("/mnt/c/Users/King/Documents/Default Project/out/dtbo.img","rb").read()
magic = b"\xd0\x0d\xfe\xed"
offs = []
i = data.find(magic)
while i != -1:
    offs.append(i)
    i = data.find(magic, i+1)
print(f"found {len(offs)} FDT blobs")
for n,o in enumerate(offs):
    totalsize = struct.unpack(">I", data[o+4:o+8])[0]
    blob = data[o:o+totalsize]
    fn = f"/tmp/dtbo-trips/dtb{n}.dtb"
    open(fn,"wb").write(blob)
    # model string
    model = ""
    m = blob.find(b"model\x00")
    if m != -1:
        # after key: padding to 4, then value string
        vstart = (m + 6 + 3) & ~3
        # actually FDT: after name\0 padded, u32 len, u32 off
        # simpler: find printable string after 'model\0'
        end = blob.find(b"\x00", m+6)
        # len/off right after padded name
        pad = (m + 6 + 3) & ~3
        ln, of = struct.unpack(">II", blob[pad:pad+8])
        s = blob[pad+of:pad+of+ln].rstrip(b"\x00").decode(errors="replace")
        model = s
    print(fn, model)
EOF

echo "=== control trips per dtb ==="
for f in /tmp/dtbo-trips/dtb*.dtb; do
    echo "--- $f"
    dtc -q -I dtb -O dts "$f" 2>/dev/null | grep -nE "control_temp|trip.*temp|ipop|foplp" | head -40
done
echo "=== DONE ==="

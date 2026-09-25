#!/usr/bin/env python3
"""Split concatenated FDT blobs out of a dtb/ image file.

usage: split-fdt.py <input> <outdir>
Writes fdt0.dtb, fdt1.dtb, ... into outdir. Prints how many were found.
"""
import struct
import sys
import os

MAGIC = b"\xd0\x0d\xfe\xed"


def main() -> int:
    src, outdir = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    data = open(src, "rb").read()
    i = data.find(MAGIC)
    n = 0
    while i != -1:
        totalsize = struct.unpack(">I", data[i + 4:i + 8])[0]
        if 1024 <= totalsize <= len(data) - i:
            with open(os.path.join(outdir, f"fdt{n}.dtb"), "wb") as f:
                f.write(data[i:i + totalsize])
            n += 1
            i = data.find(MAGIC, i + totalsize)
        else:
            i = data.find(MAGIC, i + 1)
    print(f"{src}: {n} FDTs")
    return 0


if __name__ == "__main__":
    sys.exit(main())

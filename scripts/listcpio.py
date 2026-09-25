#!/usr/bin/env python3
"""List entries of an Android ramdisk cpio (newc), auto-decompressing
gzip / lz4 / plain. Usage: listcpio.py <ramdisk-file>"""
import gzip
import lzma
import subprocess
import sys


def decompress(path: str) -> bytes:
    with open(path, "rb") as f:
        magic = f.read(4)
    if magic[:2] == b"\x1f\x8b":
        with open(path, "rb") as f:
            return gzip.decompress(f.read())
    if magic[:4] == b"\x04\x22\x4d\x18":
        r = subprocess.run(["lz4", "-dc", path], capture_output=True)
        if r.returncode != 0:
            sys.stderr.write(r.stderr.decode(errors="replace"))
            sys.exit(2)
        return r.stdout
    if magic[:2] == b"\x1f\x9d":  # compress(.Z) - rarely used
        r = subprocess.run(["sh", "-c", f"gzcat '{path}' 2>/dev/null || zcat '{path}'"],
                           capture_output=True)
        return r.stdout
    if magic[:2] == b"\xfd7":
        with open(path, "rb") as f:
            return lzma.decompress(f.read())
    # plain cpio
    with open(path, "rb") as f:
        return f.read()


def main() -> None:
    path = sys.argv[1]
    raw = decompress(path)
    off = 0
    out = []
    while off + 110 <= len(raw):
        magic = raw[off:off + 6]
        if magic not in (b"070701", b"070702"):
            break
        try:
            filesize = int(raw[off + 54:off + 62], 16)
            namesize = int(raw[off + 94:off + 102], 16)
        except ValueError:
            break
        name = raw[off + 110:off + 110 + namesize - 1].decode("latin1", "replace")
        if name == "TRAILER!!!":
            break
        hdr = 110 + namesize
        hdr = (hdr + 3) & ~3
        if filesize:
            out.append(f"{filesize:>9}  {name}")
        off = (off + hdr + filesize + 3) & ~3
    print("\n".join(out))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Print thermal *_control-temp trip values found in FDT blobs.

Usage: parse-trips.py <file>...
Accepts raw .dtb files AND container files that embed FDTs (dtbo.img,
dtb.img, an extracted vendor_kernel_boot 'dtb' component). Scans for the
FDT magic, parses each blob's structure block, and prints one
'<node-name>=<millidegrees-C>' line per matching node.
"""
import struct
import sys

NODES = {
    "big-control-temp",
    "mid-control-temp",
    "little-control-temp",
    "gpu-control-temp",
}
FDT_MAGIC = b"\xd0\x0d\xfe\xed"


def parse_fdt(buf):
    """Return (dict_of_node_temps, total_size) or None if not a sane FDT."""
    if len(buf) < 40 or buf[0:4] != FDT_MAGIC:
        return None
    try:
        magic, total, off_struct, off_strings = struct.unpack(">4I", buf[:16])
    except struct.error:
        return None
    if magic != 0xD00DFEED or total < 40 or total > len(buf):
        return None
    if off_struct >= total or off_strings >= total:
        return None
    strings = buf[off_strings:total]
    res = {}
    path = []
    off = off_struct
    end = total
    try:
        while off + 4 <= end:
            (token,) = struct.unpack(">I", buf[off:off + 4])
            off += 4
            if token == 1:  # FDT_BEGIN_NODE
                z = buf.index(b"\x00", off, end)
                path.append(buf[off:z].decode("latin1"))
                off = (z + 4) & ~3
            elif token == 2:  # FDT_END_NODE
                if path:
                    path.pop()
            elif token == 3:  # FDT_PROP
                plen, nameoff = struct.unpack(">2I", buf[off:off + 8])
                off += 8
                zend = strings.index(b"\x00", nameoff)
                pname = strings[nameoff:zend].decode("latin1")
                pdata = buf[off:off + plen]
                off = (off + plen + 3) & ~3
                if pname == "temperature" and path and path[-1] in NODES:
                    if len(pdata) == 4 and path[-1] not in res:
                        res[path[-1]] = struct.unpack(">I", pdata)[0]
            elif token == 9:  # FDT_NOP
                continue
            elif token == 10:  # FDT_END
                break
            else:
                break  # unexpected token -> stop parsing this blob
    except (ValueError, struct.error):
        pass
    return res, total


def scan(data):
    """Yield trip dicts for every FDT embedded anywhere in data."""
    off = 0
    while True:
        i = data.find(FDT_MAGIC, off)
        if i < 0:
            return
        parsed = parse_fdt(data[i:])
        if parsed is None:
            off = i + 4
            continue
        res, total = parsed
        yield res
        off = i + max(total, 4)


def main():
    if len(sys.argv) < 2:
        sys.stderr.write(__doc__)
        return 2
    for path in sys.argv[1:]:
        try:
            with open(path, "rb") as f:
                data = f.read()
        except OSError as e:
            sys.stderr.write(f"{path}: {e}\n")
            continue
        for res in scan(data):
            for node in sorted(res):
                print(f"{node}={res[node]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

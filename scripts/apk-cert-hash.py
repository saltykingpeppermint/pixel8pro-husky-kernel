#!/usr/bin/env python3
"""Print SHA-256 of the APK's v2/v3 signer certificate (same bytes KernelSU hashes).

Kernel is_baked expects: SIZE=0x3e6 HASH=79e590113c4c4c0c222978e413a5faa801666957b1212a328e46c00c69821bf7
"""
import hashlib
import struct
import sys

V2_ID = 0x7109871A
V3_ID = 0xF053AB44
MAGIC = b"APK Sig Block 42"


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


def lp(b, o):
    """length-prefixed (u32) block; returns (bytes, next_offset)."""
    n = u32(b, o)
    return b[o + 4:o + 4 + n], o + 4 + n


def main(path):
    data = open(path, "rb").read()
    eocd = data.rfind(b"PK\x05\x06")
    if eocd < 0:
        print("NO_EOCD")
        return 1
    cd_off = u32(data, eocd + 16)
    if cd_off < 32:
        print("BAD_CD_OFF")
        return 1
    # 8 bytes size-of-block (before magic) precede magic; footer 24 bytes total:
    # [size_of_block(8)][magic(16)] right before central directory
    magic_off = cd_off - 16
    if data[magic_off:magic_off + 16] != MAGIC:
        print("NO_SIG_BLOCK (v1-only APK?)")
        return 1
    block_size = u64(data, magic_off - 8)
    block_start = cd_off - block_size - 8
    # skip leading size field (8), then pairs until footer
    off = block_start + 8
    end = magic_off - 8
    found = None
    while off < end:
        pair_len = u64(data, off)
        pair_start = off + 8
        pair_id = u32(data, pair_start)
        if pair_id in (V2_ID, V3_ID):
            found = (pair_id, data[pair_start + 4:pair_start + pair_len])
            break
        off = pair_start + pair_len
    if not found:
        print("NO_V2_V3_SCHEME")
        return 1
    pair_id, payload = found
    print(f"DEBUG pair_id=0x{pair_id:08x} payload_len={len(payload)}")
    # Robust: locate DER X.509 cert: length-prefixed [0x30 0x82 <u16 == n-4>]
    # (kernel check_v2_signature hashes exactly these cert bytes)
    cert = None
    for o in range(0, len(payload) - 8):
        n = u32(payload, o)
        if not (256 <= n <= 4096) or o + 4 + n > len(payload):
            continue
        if payload[o + 4] != 0x30:
            continue
        if payload[o + 5] == 0x82 and struct.unpack(">H", payload[o + 6:o + 8])[0] == n - 4:
            cert = payload[o + 4:o + 4 + n]
            break
        if payload[o + 5] == 0x81 and payload[o + 6] == n - 4:
            cert = payload[o + 4:o + 4 + n]
            break
    if cert is None:
        print("NO_DER_CERT in pair payload")
        return 1
    h = hashlib.sha256(cert).hexdigest()
    scheme = "v2" if pair_id == V2_ID else "v3"
    print(f"scheme={scheme}")
    print(f"cert_size=0x{len(cert):x}")
    print(f"cert_sha256={h}")
    baked_hash = "79e590113c4c4c0c222978e413a5faa801666957b1212a328e46c00c69821bf7"
    baked_size = 0x3E6
    print(f"size_match={'YES' if len(cert) == baked_size else 'NO (baked 0x3e6)'}")
    print(f"hash_match={'YES  -> should be crowned' if h == baked_hash else 'NO  -> is_manager_apk()=false -> NEVER crowned'}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))

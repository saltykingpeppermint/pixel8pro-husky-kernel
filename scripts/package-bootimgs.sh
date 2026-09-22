#!/bin/bash
# Package the built kernel into two flashable boot.img files:
#   out/boot-stock.img   — kernel injected into the stock factory boot.img
#   out/boot-aicp.img    — kernel injected into the AICP boot.img
#
# Uses the AOSP's own tools from the kernel tree (official, handle Pixel
# header versions/metadata correctly; Linux magiskboot builds were retired).
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
KSRC="$HOME/kernel-shusky"
MK="$KSRC/tools/mkbootimg"           # unpack_bootimg.py + mkbootimg.py
STOCK_BOOT="$HERE/base/stock-boot.img"
AICP_BOOT="$HERE/base/aicp-boot.img"

# Locate the built kernel image (raw, uncompressed Image)
KERNEL_IMG=$(find "$KSRC/out" -name Image -o -name Image.lz4 2>/dev/null | head -1)
[ -n "$KERNEL_IMG" ] || { echo "[ERROR] no built kernel found under out/"; exit 1; }

# Pixel boots lz4_legacy-compressed kernels; compress if we got a raw Image.
case "$KERNEL_IMG" in
    *.lz4) KERNEL="$KERNEL_IMG" ;;
    *)  KERNEL=/tmp/kernel.lz4
        lz4 -l -9 "$KERNEL_IMG" "$KERNEL" >/dev/null ;;   # -l = legacy frame
esac

pack() {
    local base="$1" outname="$2"
    local work; work=$(mktemp -d)
    echo "[..] unpacking $base"
    python3 "$MK/unpack_bootimg.py" --boot_img "$base" --out "$work"

    local args=(
        --kernel "$KERNEL"
        --header_version "$(cat "$work/header_version")"
        --os_version     "$(cat "$work/os_version")"
        --os_patch_level "$(cat "$work/os_patch_level")"
    )
    # carry over everything else untouched (ramdisk, dtb, bootconfig...)
    [ -f "$work/ramdisk" ]           && args+=(--ramdisk "$work/ramdisk")
    [ -f "$work/dtb" ]               && args+=(--dtb "$work/dtb")
    [ -f "$work/bootconfig" ]        && args+=(--bootconfig "$(cat "$work/bootconfig")")
    for r in "$work"/ramdisk*.gz; do  # multi-ramdisk v4 layouts
        [ -e "$r" ] && args+=(--ramdisk "$r")
    done

    mkdir -p "$HERE/out"
    python3 "$MK/mkbootimg.py" "${args[@]}" --output "$HERE/out/$outname"
    echo "[OK]  $HERE/out/$outname"
    rm -rf "$work"
}

[ -f "$STOCK_BOOT" ] && pack "$STOCK_BOOT"  boot-stock.img
[ -f "$AICP_BOOT"  ] && pack "$AICP_BOOT"   boot-aicp.img

echo
echo "Flash (unlocked bootloader):"
echo "  adb reboot bootloader"
echo "  fastboot flash boot out/boot-<variant>.img"
echo "  fastboot reboot"
echo "Keep a backup of your ORIGINAL boot.img — restore with:"
echo "  fastboot flash boot <original-boot.img>"

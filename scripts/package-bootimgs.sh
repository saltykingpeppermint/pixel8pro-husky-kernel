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

# Locate the built kernel image. Pin to the dist copy: it must be the kernel
# WE built from source (--config=use_source_tree_aosp) with CONFIG_KSU=y.
# The previous blind `find out/ | head -1` could pick up an unrelated copy of
# Google's downloaded prebuilt GKI — which has no KernelSU at all.
DIST="$KSRC/out/shusky/dist"
if   [ -f "$DIST/Image" ];     then KERNEL_IMG="$DIST/Image"
elif [ -f "$DIST/Image.lz4" ]; then KERNEL_IMG="$DIST/Image.lz4"
else
    KERNEL_IMG=$(find "$KSRC/out" -name Image -o -name Image.lz4 2>/dev/null | head -1)
fi
[ -n "$KERNEL_IMG" ] || { echo "[ERROR] no built kernel found under out/"; exit 1; }
echo "[..] kernel image: $KERNEL_IMG"

# Hard guard: never package a kernel without KernelSU — that is exactly the
# failure mode we hit once (prebuilt GKI slipped into dist). Refuse instead
# of silently shipping a rootless boot.img.
EXTRACT="$KSRC/aosp/scripts/extract-ikconfig"
case "$KERNEL_IMG" in
    *.lz4)
        echo "[warn] lz4-compressed image — CONFIG_KSU guard skipped (raw Image preferred)"
        ;;
    *)
        if [ -f "$EXTRACT" ]; then
            if ! bash "$EXTRACT" "$KERNEL_IMG" 2>/dev/null | grep -q '^CONFIG_KSU=y'; then
                echo "[ERROR] $KERNEL_IMG does NOT contain CONFIG_KSU=y — refusing to package."
                echo "        (looks like Google's prebuilt GKI; rebuild with"
                echo "         ./build_shusky.sh --jobs=5 --config=use_source_tree_aosp)"
                exit 1
            fi
            echo "[ok] CONFIG_KSU=y verified inside kernel image"
        else
            echo "[warn] $EXTRACT missing — CONFIG_KSU guard skipped"
        fi
        ;;
esac

# Pixel boots lz4_legacy-compressed kernels; compress if we got a raw Image.
case "$KERNEL_IMG" in
    *.lz4) KERNEL="$KERNEL_IMG" ;;
    *)  KERNEL=/tmp/kernel.lz4
        rm -f "$KERNEL"
        lz4 -l -9 -f "$KERNEL_IMG" "$KERNEL" >/dev/null ;;   # -l = legacy frame, -f = overwrite leftover
esac

pack() {
    local base="$1" outname="$2"
    local work; work=$(mktemp -d)
    echo "[..] unpacking $base"
    # NOTE: this unpack_bootimg.py writes ONLY payload files (kernel, ramdisk,
    # dtb, bootconfig) — it prints metadata to stdout and creates NO
    # header_version/os_version/os_patch_level/cmdline files (first run died on
    # `cat header_version`). Parse the stdout instead.
    local up
    up=$(python3 "$MK/unpack_bootimg.py" --boot_img "$base" --out "$work") || {
        echo "[ERROR] unpack failed for $base"; rm -rf "$work"; exit 1; }
    echo "$up"

    local hv ov opl cl
    hv=$(echo "$up" | sed -n 's/^boot image header version: //p' | head -1)
    ov=$(echo "$up" | sed -n 's/^os version: //p'           | head -1)
    opl=$(echo "$up" | sed -n 's/^os patch level: //p'      | head -1)
    cl=$(echo "$up" | sed -n 's/^command line args: //p'    | head -1)
    [ -n "$hv" ] || hv=4
    case "$ov"  in ''|None) ov=''  ;; esac
    case "$opl" in ''|None) opl='' ;; esac

    local args=(
        --kernel "$KERNEL"
        --header_version "$hv"
    )
    # Header v3/v4 mandates 4096-byte pages; mkbootimg.py defaults to 2048 and
    # would write a misaligned, unbootable image (no override exists in-tool).
    [ "$hv" -ge 3 ] && args+=(--pagesize 4096)
    [ -n "$ov"  ] && args+=(--os_version "$ov")
    [ -n "$opl" ] && args+=(--os_patch_level "$opl")
    [ -n "$cl"  ] && args+=(--cmdline "$cl")   # carry base cmdline (was dropped!)
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

# Companion images from the SAME build. Kernel and its modules are locked
# together by vermagic + MODVERSIONS CRCs: mixing this kernel with any
# ROM-provided module partition gets those modules rejected at load time
# (wifi/bt dead). dtbo carries the patched thermal-trip DTBs.
for f in dtbo.img vendor_dlkm.img system_dlkm.img vendor_kernel_boot.img; do
    if [ -f "$DIST/$f" ]; then
        cp -f "$DIST/$f" "$HERE/out/"
        echo "[OK]  companion out/$f"
    else
        echo "[warn] missing companion in dist: $f"
    fi
done

echo
echo "Flash set (unlocked bootloader; back up originals first):"
echo "  adb reboot bootloader"
echo "  fastboot flash boot out/boot-<variant>.img"
echo "  fastboot flash dtbo out/dtbo.img"
echo "  fastboot flash vendor_kernel_boot out/vendor_kernel_boot.img"
echo "  fastboot reboot fastboot              # fastbootd: logical partitions"
echo "  fastboot flash system_dlkm out/system_dlkm.img"
echo "  fastboot flash vendor_dlkm out/vendor_dlkm.img"
echo "  fastboot reboot"
echo "Keep backups of the ORIGINAL images — restore with:"
echo "  fastboot flash <partition> <original-file>"

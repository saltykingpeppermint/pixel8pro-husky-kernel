#!/bin/bash
# Resolve Image provenance: dist Image == our build, or Google's prebuilt?
KSRC=/home/king/kernel-shusky
BZ="$KSRC/out/bazel/output_user_root/5d32986b71ff314335b4a702f008fef0"
DIST="$KSRC/out/shusky/dist"
MIX="$BZ/execroot/__main__/bazel-out/k8-fastbuild/bin/private/devices/google/shusky/kernel_kbuild_mixed_tree/Image"

echo "=== candidates present ==="
for f in "$DIST/Image" "$BZ/external/gki_prebuilts/Image" "$BZ/external/gki_prebuilts_Image/file/Image" "$MIX"; do
    if [ -f "$f" ]; then echo "EXISTS: $f"; else echo "absent: $f"; fi
done

echo ""
echo "=== sha256 ==="
sha256sum "$DIST/Image" "$BZ/external/gki_prebuilts/Image" "$BZ/external/gki_prebuilts_Image/file/Image" "$MIX" 2>/dev/null

echo ""
echo "=== CONFIG_KSU=y inside EACH candidate (embedded ikconfig) ==="
for f in "$DIST/Image" "$BZ/external/gki_prebuilts/Image" "$BZ/external/gki_prebuilts_Image/file/Image" "$MIX"; do
    [ -f "$f" ] || continue
    OFF=$(grep -abo -m1 'IKCFG_ST' "$f" | cut -d: -f1)
    if [ -n "${OFF:-}" ]; then
        KSUMATCH=$(tail -c "+$((OFF + 9))" "$f" | gzip -dc 2>/dev/null | grep -c '^CONFIG_KSU=y')
        LOCVER=$(tail -c "+$((OFF + 9))" "$f" | gzip -dc 2>/dev/null | grep -m1 '^CONFIG_LOCALVERSION=')
        echo "KSU=$KSUMATCH  $LOCVER  <- $f"
    else
        echo "no IKCFG_ST <- $f"
    fi
done

echo ""
echo "=== definition of gki_prebuilts_Image ==="
ls -la "$BZ/external/gki_prebuilts_Image/" 2>/dev/null
cat "$BZ/external/gki_prebuilts_Image/BUILD" 2>/dev/null
grep -rn "gki_prebuilts_Image" "$KSRC/BUILD.bazel" "$KSRC/MODULE.bazel" "$KSRC/workspace.bzl" "$KSRC/WORKSPACE" 2>/dev/null | head -10
grep -rn "gki_prebuilts" "$KSRC/private/devices/google/shusky/"*.bzl "$KSRC/private/devices/google/shusky/BUILD.bazel" 2>/dev/null | head -10

echo ""
echo "=== where do shusky BUILD rules get their kernel Image? ==="
grep -rn "gki_prebuilts\|kernel_build\|kernel_images" "$KSRC/private/devices/google/shusky/BUILD.bazel" 2>/dev/null | head -25

echo ""
echo "=== git repos under source (depth<=4) ==="
find "$KSRC" -maxdepth 4 -name '.git' -printf '%h\n' 2>/dev/null | head -20

echo "=== provenance done ==="

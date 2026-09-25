#!/bin/bash
# Resolve: does dist/Image REALLY contain CONFIG_KSU, or is it stale?
KSRC=/home/king/kernel-shusky
DIST="$KSRC/out/shusky/dist"
IK=/tmp/ik.txt

echo "=== A. raw grep inside Image binary (ground truth, no pipeline) ==="
echo -n "CONFIG_KSU=y            count: "; grep -a -c 'CONFIG_KSU=y' "$DIST/Image" || true
echo -n "'# CONFIG_KSU is not set' count: "; grep -a -c '# CONFIG_KSU is not set' "$DIST/Image" || true
echo -n "CONFIG_MODVERSIONS=y    count: "; grep -a -c 'CONFIG_MODVERSIONS=y' "$DIST/Image" || true
echo -n "IKCFG_ST                count: "; grep -a -c 'IKCFG_ST' "$DIST/Image" || true

echo ""
echo "=== B. re-extract embedded ikconfig, inspect ==="
OFF=$(grep -abo -m1 'IKCFG_ST' "$DIST/Image" | cut -d: -f1)
echo "offset=${OFF:-ABSENT}"
if [ -n "${OFF:-}" ]; then
    tail -c "+$((OFF + 9))" "$DIST/Image" | gzip -dc > "$IK" 2>/dev/null
    echo "lines=$(wc -l < "$IK" < /dev/null)"
    echo "--- KSU / sig / modversions lines ---"
    grep -E 'CONFIG_KSU|CONFIG_MODVERSIONS=|CONFIG_MODULE_SIG=|CONFIG_LOCALVERSION=' "$IK" || echo "(no KSU lines at all)"
    echo "--- tail of embedded config (last 5 lines) ---"
    tail -5 "$IK"
fi

echo ""
echo "=== C. git log: when were the patches committed ==="
cd "$KSRC" || exit 1
git log --format='%h %ci %s' -8

echo ""
echo "=== D. every Image artifact under out/ (mtime) ==="
find "$KSRC/out" -name 'Image' -printf '%TY-%Tm-%Td %TH:%TM  %p\n' 2>/dev/null | sort | tail -15

echo ""
echo "=== E. dist key file mtimes ==="
stat -c '%y  %n' "$DIST/.config" "$DIST/Image" "$DIST/dtbo.img" "$DIST/vendor_dlkm.img" 2>/dev/null

echo "=== diagnose done ==="

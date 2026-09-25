#!/bin/bash
# Prove CONFIG_KSU=y is in the BUILD RESULT:
#  1. dist .config (copied by the dist rule from the build)
#  2. ikconfig embedded inside Image (IKCFG_ST ... gzip ... IKCFG_ED)
#  3. corroborating 'KernelSU' string inside Image (built-in code)
set -uo pipefail
KSRC=/home/king/kernel-shusky
DIST="$KSRC/out/shusky/dist"

echo "=== 1. dist .config ==="
grep -E '^CONFIG_KSU|^CONFIG_IKCONFIG|^CONFIG_MODULES=' "$DIST/.config" || echo "(nothing matched)"

echo ""
echo "=== extract-ikconfig tool ==="
ls -l "$KSRC/scripts/extract-ikconfig" 2>/dev/null || echo "scripts/extract-ikconfig ABSENT"

echo ""
echo "=== 2. embedded ikconfig inside Image ==="
if [ -f "$DIST/Image" ]; then
    OFF=$(grep -abo -m1 'IKCFG_ST' "$DIST/Image" | head -1 | cut -d: -f1)
    if [ -n "${OFF:-}" ]; then
        echo "IKCFG_ST found at offset $OFF"
        tail -c "+$((OFF + 9))" "$DIST/Image" | gzip -dc > /tmp/ik.txt 2>/tmp/ik.err
        if [ -s /tmp/ik.txt ]; then
            echo "gunzip OK ($(wc -l < /tmp/ik.txt) lines). CONFIG_KSU lines:"
            grep -E '^CONFIG_KSU' /tmp/ik.txt || echo "!!! CONFIG_KSU NOT IN EMBEDDED CONFIG !!!"
        else
            echo "gunzip FAILED:"; cat /tmp/ik.err
        fi
    else
        echo "IKCFG_ST not found (CONFIG_IKCONFIG not enabled?)"
    fi
else
    echo "dist/Image missing"
fi

echo ""
echo "=== 3. KernelSU strings inside Image ==="
if [ -f "$DIST/Image" ]; then
    grep -a -c 'KernelSU' "$DIST/Image" 2>/dev/null || echo "0 occurrences"
    grep -a -o -m1 'kernelsu[^ ]*' "$DIST/Image" 2>/dev/null | head -3 || true
fi

echo ""
echo "=== ksu verify done ==="

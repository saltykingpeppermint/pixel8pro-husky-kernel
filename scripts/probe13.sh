#!/bin/bash
# Reproduce Kleaf's savedefconfig check locally + inspect KSU Kconfig deps.
KSRC=/home/king/kernel-shusky

echo "=== KSU Kconfig content ==="
for f in "$KSRC/KernelSU-Next/kernel/Kconfig" "$KSRC/aosp/drivers/kernelsu/Kconfig"; do
    if [ -f "$f" ]; then
        echo "--- $f ---"
        cat "$f"
        break
    fi
done

echo
echo "=== does the kernelsu symlink resolve? ==="
ls -la "$KSRC/aosp/drivers/kernelsu/" | head -5

echo
echo "=== run make savedefconfig (out-of-tree) ==="
rm -rf /tmp/kcfg
mkdir -p /tmp/kcfg
make -C "$KSRC/aosp" O=/tmp/kcfg ARCH=arm64 savedefconfig > /tmp/kcfg.log 2>&1
echo "rc=$?"
tail -6 /tmp/kcfg.log

echo
echo "=== KSU resolved in the produced full .config? ==="
grep -n 'CONFIG_KSU' /tmp/kcfg/.config || echo "(NOT in .config -> unknown symbol or deps unmet)"

echo
echo "=== KSU in savedefconfig output? ==="
grep -n 'CONFIG_KSU' /tmp/kcfg/defconfig || echo "(NOT in savedefconfig output)"

echo
echo "=== canonical diff (source gki_defconfig vs savedefconfig) ==="
diff -u "$KSRC/aosp/arch/arm64/configs/gki_defconfig" /tmp/kcfg/defconfig
echo "diff rc=$?"

echo "=== probe13 done ==="

#!/system/bin/sh
echo "=== 1. did insmod_sh_husky run this boot? ==="
getprop vendor.common.modules.ready
echo "svc insmod_sh:      $(getprop init.svc.insmod_sh)"
echo "svc insmod_sh_husky: $(getprop init.svc.insmod_sh_husky)"
echo
echo "=== 2. is dmesg buffer still at boot? ==="
dmesg | head -2 | cut -c1-80
echo "buffer first timestamp above; uptime: $(cut -d' ' -f1 /proc/uptime)s"
echo
echo "=== 3. any dhd lines currently in dmesg ==="
dmesg | grep -icE "dhd|bcmdhd"
echo
echo "=== 4. logcat insmod/modprobe lines ==="
logcat -d -b all 2>/dev/null | grep -iE "insmod.sh|modprobe.*bcmdhd|bcmdhd4398" | head -10
echo "=== DONE ==="

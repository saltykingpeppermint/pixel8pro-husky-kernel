#!/system/bin/sh
# On a FRESH boot: retry module load once (chip may be warm now), capture full dhd window
echo "=== uptime ==="; cut -d' ' -f1 /proc/uptime
echo "=== current modules ==="; grep -E "bcmdhd|cfg80211" /proc/modules | head -3
echo "=== retry insmod (2nd attempt this boot) ==="
KDIR=/vendor_dlkm/lib/modules/$(uname -r)
if [ -d "$KDIR" ]; then
    MOD="$KDIR/extra/private/google-modules/wlan/bcm4398/bcmdhd4398.ko"
    if [ -f "$MOD" ]; then
        # ensure cfg80211 present (it is, from boot)
        insmod "$MOD" 2>&1
        echo "insmod rc=$?"
    else
        echo "module path not found: $MOD"
        find "$KDIR" -name "bcmdhd4398.ko" 2>/dev/null
    fi
else
    echo "KDIR not found: $KDIR"
    ls /vendor_dlkm/lib/modules/ 2>/dev/null
fi
sleep 4
echo "=== dmesg dhd/pcie after retry ==="
dmesg | grep -E "dhd|bcmdhd|Set PERST|Link is not up|LTSSM:|No Broadcom|Register interface|wlan0" | tail -30
echo "=== net ifaces ==="
ls /sys/class/net | grep -iE "wlan|p2p" || echo "(no wlan)"
echo "=== DONE ==="

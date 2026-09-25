#!/bin/bash
# Compare stock Google vendor_dlkm vs OUR vendor_dlkm: blocklist + load list + module versions
set -u
STOCK="/mnt/d/pixel8pro-factory/out/husky_beta-bp31.250610.009/vendor_dlkm-stock.img"
OURS="/mnt/c/Users/King/Documents/Default Project/out/vendor_dlkm.img"
MNT=/tmp/vdlkm_cmp

echo "=== file types ==="
file "$STOCK" "$OURS" 2>/dev/null

extract_and_show() {
    local img="$1" label="$2"
    rm -rf "$MNT"; mkdir -p "$MNT"
    if mount -o loop,ro "$img" "$MNT" 2>/dev/null; then
        echo "--- $label: mounts OK"
    else
        echo "--- $label: loop mount FAILED, trying debugfs"
        return 1
    fi
    local dir
    dir=$(ls -d "$MNT"/lib/modules/*/ 2>/dev/null | head -1)
    echo "module dir: $dir"
    echo "[blocklist]"
    cat "$dir/modules.blocklist" 2>/dev/null
    echo "[load: wifi lines]"
    grep -iE "bcmdhd|cfg80211|wlan" "$dir/modules.load" 2>/dev/null
    echo "[bcmdhd ko present?]"
    ls -la "$dir"/extra/private/google-modules/wlan/bcm4398/ 2>/dev/null
    umount "$MNT"
}

echo
echo "################ STOCK (Google factory) ################"
if ! extract_and_show "$STOCK" stock; then
    # try debugfs fallback for file reads
    D=$(debugfs -R "ls -l /lib/modules" "$STOCK" 2>/dev/null | awk '{print $NF}' | grep -E "^[0-9]" | head -1)
    echo "debugfs module dirs: $D"
fi

echo
echo "################ OURS (built) ################"
extract_and_show "$OURS" ours

echo "=== DONE ==="

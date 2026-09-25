#!/bin/bash
# Read blocklist/load files from ext4 images via debugfs (no mount/root needed)
set -u
STOCK="/mnt/d/pixel8pro-factory/out/husky_beta-bp31.250610.009/vendor_dlkm-stock.img"
OURS="/mnt/c/Users/King/Documents/Default Project/out/vendor_dlkm.img"

show() {
    local img="$1" label="$2"
    echo "################ $label ################"
    # find the modules dir
    local d
    d=$(debugfs -R "ls -p /lib/modules" "$img" 2>/dev/null | tr -d '/' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+[^/]*' | head -1)
    echo "modules dir: /lib/modules/$d"
    local base="/lib/modules/$d"
    echo "[modules.blocklist]"
    debugfs -R "cat $base/modules.blocklist" "$img" 2>/dev/null
    echo
    echo "[modules.load wifi lines]"
    debugfs -R "cat $base/modules.load" "$img" 2>/dev/null | grep -iE "bcmdhd|cfg80211|wlan"
    echo "[bcm4398 dir listing]"
    debugfs -R "ls -l $base/extra/private/google-modules/wlan/bcm4398" "$img" 2>/dev/null
    echo "[bcmdhd module vermagic (strings on .ko first 1 line)]"
    local ko="$base/extra/private/google-modules/wlan/bcm4398/bcmdhd4398.ko"
    debugfs -R "dump $ko /tmp/ko_$label.ko" "$img" 2>/dev/null
    if [ -f "/tmp/ko_$label.ko" ]; then
        modinfo "/tmp/ko_$label.ko" 2>/dev/null | grep -E "vermagic|name" | head -3
        ls -la "/tmp/ko_$label.ko"
    fi
    echo
}

show "$STOCK" stock
show "$OURS" ours
echo "=== DONE ==="

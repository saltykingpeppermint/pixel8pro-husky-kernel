#!/bin/bash
STOCK="/mnt/d/pixel8pro-factory/out/husky_beta-bp31.250610.009/vendor_dlkm-stock.img"
OURS="/mnt/c/Users/King/Documents/Default Project/out/vendor_dlkm.img"
ODIR="/lib/modules"
UDIR="/lib/modules/6.1.124-android14-11-g51d090c67d6e"

echo "################ STOCK modules.blocklist ################"
debugfs -R "cat $ODIR/modules.blocklist" "$STOCK" 2>/dev/null
echo
echo "################ STOCK modules.load ################"
debugfs -R "cat $ODIR/modules.load" "$STOCK" 2>/dev/null
echo
echo "################ STOCK modules.softdep ################"
debugfs -R "cat $ODIR/modules.softdep" "$STOCK" 2>/dev/null
echo
echo "################ STOCK 16k-mode dir listing (wifi only) ################"
debugfs -R "ls $ODIR/16k-mode" "$STOCK" 2>/dev/null | grep -iE "bcmdhd|cfg80211|wlan|blocklist|load" 
echo
echo "################ OURS modules.blocklist ################"
debugfs -R "cat $UDIR/modules.blocklist" "$OURS" 2>/dev/null
echo
echo "################ OURS modules.load ################"
debugfs -R "cat $UDIR/modules.load" "$OURS" 2>/dev/null
echo
echo "=== DONE ==="

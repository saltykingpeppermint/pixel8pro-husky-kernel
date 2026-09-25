#!/bin/bash
STOCK="/mnt/d/pixel8pro-factory/out/husky_beta-bp31.250610.009/vendor_dlkm-stock.img"
OURS="/mnt/c/Users/King/Documents/Default Project/out/vendor_dlkm.img"
echo "=== stock: ls /lib ==="
debugfs -R "ls -l /lib" "$STOCK" 2>/dev/null
echo "=== stock: ls /lib/modules ==="
debugfs -R "ls -l /lib/modules" "$STOCK" 2>/dev/null
echo "=== stock: ls / (root) ==="
debugfs -R "ls -l /" "$STOCK" 2>/dev/null | head -20
echo "=== ours: ls /lib/modules raw ==="
debugfs -R "ls -p /lib/modules" "$OURS" 2>/dev/null

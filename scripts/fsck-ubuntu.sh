#!/bin/bash
# Rescue helper (run INSIDE the WslTest rescue distro by monitor-wsl.ps1).
# Finds the Ubuntu-24.04 vhdx among attached disks by CONTENT signature
# (never by disk order — a mystery 1 TB disk is also attached), then fscks it.
# Self-logs to out/fsck.log on C: (e2fsck output can be large; the monitor
# must not have that piped back through a possibly-filling pipe).
LOG="/mnt/c/Users/King/Documents/Default Project/out/fsck.log"
mkdir -p "$(dirname "$LOG")"
exec >> "$LOG" 2>&1

STAMP=$(date '+%Y-%m-%dT%H:%M:%S%z')
echo "=== FSCK START $STAMP ==="

target=""
for d in /dev/sd*; do
  [ -b "$d" ] || continue
  mkdir -p /tmp/probe
  if mount -o ro "$d" /tmp/probe 2>/dev/null; then
    # Ubuntu signature: king's home dir + a wsl.conf
    if [ -d /tmp/probe/home/king ] && [ -f /tmp/probe/etc/wsl.conf ]; then
      target="$d"
      umount /tmp/probe
      break
    fi
    umount /tmp/probe
  fi
done

if [ -z "$target" ]; then
  echo "FSCK_TARGET_NOT_FOUND (refusing to fsck anything unverified)"
  echo "=== FSCK END $(date '+%Y-%m-%dT%H:%M:%S%z') ==="
  exit 2
fi

echo "TARGET=$target"

# Locate e2fsck (Alpine rescue distro: /sbin, /usr/sbin or busybox PATH).
E2FSCK=""
for c in /sbin/e2fsck /usr/sbin/e2fsck e2fsck; do
  if command -v "$c" >/dev/null 2>&1; then E2FSCK="$c"; break; fi
done
if [ -z "$E2FSCK" ]; then
  echo "E2FSCK_NOT_FOUND (install e2fsprogs in the rescue distro)"
  echo "=== FSCK END $(date '+%Y-%m-%dT%H:%M:%S%z') ==="
  exit 3
fi
echo "E2FSCK=$E2FSCK"

# Never kill this: e2fsck -f writes; interrupting it would worsen things.
"$E2FSCK" -fy "$target"
rc=$?
echo "FSCK_RC=$rc (bitmask: 0=clean, nonzero=issues found/fixed; low bits=errors corrected)"
echo "=== FSCK END $(date '+%Y-%m-%dT%H:%M:%S%z') ==="
exit 0

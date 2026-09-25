#!/bin/bash
# Which lineage is the installed manager, and what does our repo's manager look like?
set -u
P="/mnt/c/Users/King/Documents/Default Project"
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. repo HEAD: me.weishu anywhere? ==="
grep -rn "me\.weishu" "$K" --exclude-dir=.git 2>/dev/null | head -10

echo
echo "=== 2. manager manifest: activities / processes ==="
grep -nE "MainActivity|android:process|<activity" "$K/manager/app/src/main/AndroidManifest.xml" 2>/dev/null | head -20

echo
echo "=== 3. manager build.gradle.kts lines 1-60 (applicationId?) ==="
sed -n '1,60p' "$K/manager/app/build.gradle.kts"

echo
echo "=== 4. installed APK: interesting members ==="
unzip -l "$P/out/manager-installed.apk" 2>/dev/null | grep -E "libksud|classes[0-9]*\.dex|assets" | head -12

echo
echo "=== 5. installed APK libksud.so: version + lineage strings ==="
rm -rf /tmp/ksuapk && mkdir -p /tmp/ksuapk
unzip -o -q "$P/out/manager-installed.apk" "lib/arm64/libksud.so" -d /tmp/ksuapk 2>/dev/null
if [ -f /tmp/ksuapk/lib/arm64/libksud.so ]; then
    strings -n 4 /tmp/ksuapk/lib/arm64/libksud.so | grep -aE "^[0-9]+\.[0-9]+\.[0-9]+ \(uapi" | head -3
    strings -n 6 /tmp/ksuapk/lib/arm64/libksud.so | grep -aiE "me\.weishu|com\.rifsxd|ksunext" | head -8
else
    echo "libksud.so not in APK"
fi

echo
echo "=== 6. installed APK AndroidManifest strings (process hints) ==="
unzip -p "$P/out/manager-installed.apk" AndroidManifest.xml > /tmp/ksuapk/AM.bin 2>/dev/null
strings -n 6 /tmp/ksuapk/AM.bin 2>/dev/null | grep -aiE "root|main\.jar|ksu" | head -15

echo
echo "=== 7. repo: what declares ':root:' or main.jar at HEAD (all files) ==="
grep -rn "main\.jar\|:root:" "$K" --exclude-dir=.git 2>/dev/null | head -10

echo
echo "=== DONE ==="

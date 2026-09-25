#!/bin/bash
# Does the OFFICIAL KSU-Next v3.4.0 APK match our baked manager signature?
set -u
P="/mnt/c/Users/King/Documents/Default Project"
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. official APK cert vs baked hash ==="
python3 "$P/scripts/apk-cert-hash.py" "$P/out/manager-ksunext-3.4.0.apk"

echo
echo "=== 2. official APK manifest package (UTF-16 strings) ==="
unzip -p "$P/out/manager-ksunext-3.4.0.apk" AndroidManifest.xml 2>/dev/null | strings -e l | grep -iE "rifsxd|weishu|MainActivity" | head -8

echo
echo "=== 3. installed (old) APK manifest package (UTF-16 strings) ==="
unzip -p "$P/out/manager-installed.apk" AndroidManifest.xml 2>/dev/null | strings -e l | grep -iE "rifsxd|weishu|MainActivity|root" | head -12

echo
echo "=== 4. v3.3.0 tag: applicationId / namespace ==="
git -C "$K" show v3.3.0:manager/app/build.gradle.kts 2>/dev/null | grep -nE "applicationId|namespace" | head -5

echo
echo "=== 5. v3.3.0 tag: main.jar / app_process / :root: anywhere ==="
git -C "$K" grep -l -E "main\.jar|app_process" v3.3.0 2>/dev/null | head -10

echo
echo "=== DONE ==="

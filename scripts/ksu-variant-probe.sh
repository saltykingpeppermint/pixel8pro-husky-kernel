#!/bin/bash
# Is the installed userspace original-KSU or KSU-Next? (tags, main.jar, :root:)
set -u
P="/mnt/c/Users/King/Documents/Default Project"
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. local tags ==="
git -C "$K" tag | tail -10

echo
echo "=== 2. v3.3.0 default package in ksud cli.rs (if tag exists) ==="
if git -C "$K" rev-parse v3.3.0 >/dev/null 2>&1; then
    git -C "$K" show v3.3.0:userspace/ksud/src/cli.rs 2>/dev/null | grep -n "me.weishu.kernelsu\|com.rifsxd.ksunext" | head -10
else
    echo "no v3.3.0 tag locally"
fi

echo
echo "=== 3. whole repo: main.jar / :root: / app_process ==="
grep -rn "main\.jar\|:root:\|app_process" "$K/manager" "$K/userspace" "$K/kernel" 2>/dev/null | grep -v "\.git/" | head -20

echo
echo "=== 4. v3.3.0: main.jar / :root: (historical) ==="
if git -C "$K" rev-parse v3.3.0 >/dev/null 2>&1; then
    git -C "$K" grep -n "main\.jar\|:root:" v3.3.0 -- manager userspace 2>/dev/null | head -15
fi

echo
echo "=== 5. what does 'debug package' print in v3.4.0 ksud? ==="
grep -rn -B4 -A8 "Print default package name\|fn package" "$K/userspace/ksud/src/cli.rs" | head -40

echo
echo "=== DONE ==="

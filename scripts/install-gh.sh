#!/bin/bash
# One-time: install GitHub CLI into WSL
set -euo pipefail
cd /tmp
VER=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | python3 -c 'import sys,json;print(json.load(sys.stdin)["tag_name"])')
echo "version: $VER"
curl -sL "https://github.com/cli/cli/releases/download/${VER}/gh_${VER#v}_linux_amd64.tar.gz" -o gh.tgz
tar xzf gh.tgz
sudo install -m755 "gh_${VER#v}_linux_amd64/bin/gh" /usr/local/bin/gh
gh --version | head -1
gh auth status 2>&1 || echo NOT_AUTHED_YET

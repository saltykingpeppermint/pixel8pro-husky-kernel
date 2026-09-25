#!/bin/bash
# Commit + push the project repo (git only exists inside WSL; identity via -c).
# Usage: git-commit-push.sh "area: message"
set -euo pipefail
MSG="${1:?usage: git-commit-push.sh <message>}"
cd "$(dirname "$0")/.."

ID=(-c user.name=King -c user.email=king@local)
git add -A
if git diff --cached --quiet; then
    echo "[skip] nothing staged"
    exit 0
fi
git "${ID[@]}" commit -m "$MSG"
git "${ID[@]}" push origin HEAD
echo "[ok] pushed: $(git log --oneline -1)"

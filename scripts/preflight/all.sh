#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ERRORS=0
for tool in git python3; do
  if command -v "$tool" >/dev/null 2>&1; then echo "[OK] $tool"; else echo "[ERROR] missing $tool"; ERRORS=$((ERRORS+1)); fi
done
for dir in scripts/gates scripts/workflow docs/workflow docs/worklog; do
  [ -d "$ROOT/$dir" ] && echo "[OK] $dir" || { echo "[ERROR] missing $dir"; ERRORS=$((ERRORS+1)); }
done
bash "$ROOT/scripts/gates/all.sh" --dry-run >/dev/null && echo "[OK] gate dry-run" || { echo "[ERROR] gate dry-run"; ERRORS=$((ERRORS+1)); }
exit "$ERRORS"

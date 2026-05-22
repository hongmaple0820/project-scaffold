#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ERRORS=0

for tool in git python3; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "[OK] $tool"
  else
    echo "[ERROR] missing $tool"
    ERRORS=$((ERRORS+1))
  fi
done

for file in .scale/workspace.json .scale/governance.lock.json .agent/project.json Makefile AGENTS.md CLAUDE.md; do
  [ -f "$ROOT/$file" ] && echo "[OK] $file" || { echo "[ERROR] missing $file"; ERRORS=$((ERRORS+1)); }
done

for dir in .agent scripts/gates scripts/hooks scripts/workflow docs/workflow docs/guides docs/workflow/templates; do
  [ -d "$ROOT/$dir" ] && echo "[OK] $dir" || { echo "[ERROR] missing $dir"; ERRORS=$((ERRORS+1)); }
done

bash "$ROOT/scripts/validate-config.sh" >/dev/null && echo "[OK] validate-config" || { echo "[ERROR] validate-config"; ERRORS=$((ERRORS+1)); }
bash "$ROOT/scripts/gates/all.sh" --dry-run >/dev/null && echo "[OK] gate dry-run" || { echo "[ERROR] gate dry-run"; ERRORS=$((ERRORS+1)); }

exit "$ERRORS"

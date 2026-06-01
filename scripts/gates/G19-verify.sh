#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[G19] Error handling gate"

CHANGED=$(cd "$ROOT" && git diff --name-only HEAD 2>/dev/null | grep -E '\.(ts|js|java|py)$' || true)

if [ -z "$CHANGED" ]; then
  echo "[G19] no changed source files; skip"
  exit 0
fi

VIOLATIONS=0
while IFS= read -r file; do
  fullpath="$ROOT/$file"
  [ -f "$fullpath" ] || continue
  if grep -Pn 'catch\s*\([^)]*\)\s*\{\s*\}' "$fullpath" 2>/dev/null; then
    echo "[G19] empty catch block in $file"
    VIOLATIONS=$((VIOLATIONS+1))
  fi
done <<< "$CHANGED"

if [ "$VIOLATIONS" -gt 0 ]; then
  echo "[G19] $VIOLATIONS error handling violations"
  exit 1
fi

echo "[G19] passed"

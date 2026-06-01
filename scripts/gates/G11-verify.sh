#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[G11] Workflow completeness gate"

STATE="$ROOT/.agent/state/current.json"
if [ ! -f "$STATE" ]; then
  echo "[G11] no workflow state; skip"
  exit 0
fi

LEVEL=$(grep -o '"level": *"[^"]*"' "$STATE" | head -1 | sed 's/.*": *"//;s/"//' || true)
case "$LEVEL" in
  M|L|CRITICAL) ;;
  *) echo "[G11] level $LEVEL does not require full phase completion"; exit 0 ;;
esac

MISSING=()
for p in explore plan execute verify settle; do
  if ! grep -qi "$p" "$STATE" 2>/dev/null; then
    MISSING+=("$p")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "[G11] incomplete phases: ${MISSING[*]}"
  exit 1
fi

echo "[G11] passed"

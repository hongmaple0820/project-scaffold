#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[G12] Evidence quality gate"

STATE="$ROOT/.agent/state/current.json"
if [ ! -f "$STATE" ]; then
  echo "[G12] no workflow state; skip"
  exit 0
fi

LEVEL=$(grep -o '"level": *"[^"]*"' "$STATE" | head -1 | sed 's/.*": *"//;s/"//' || true)
case "$LEVEL" in
  M|L|CRITICAL) ;;
  *) echo "[G12] level $LEVEL does not require evidence"; exit 0 ;;
esac

ARTIFACTS_DIR=$(grep -o '"artifacts_dir": *"[^"]*"' "$STATE" | head -1 | sed 's/.*": *"//;s/"//' || true)
if [ -z "$ARTIFACTS_DIR" ]; then
  echo "[G12] no artifacts directory; skip"
  exit 0
fi

MISSING=()
for f in runtime.md reality-check.md resource-cleanup.md; do
  if [ ! -f "$ROOT/$ARTIFACTS_DIR/$f" ]; then
    MISSING+=("$f")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "[G12] missing evidence artifacts: ${MISSING[*]}"
  exit 1
fi

echo "[G12] passed"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[G9] Self-governance: version consistency"

LOCK="$ROOT/.scale/governance.lock.json"
if [ ! -f "$LOCK" ]; then
  echo "[G9] no governance lock; skip"
  exit 0
fi

if command -v scale >/dev/null 2>&1; then
  INSTALLED=$(scale --version 2>/dev/null | head -1 | tr -d '[:space:]')
  LOCKED=$(grep -o '"scaleVersion": *"[^"]*"' "$LOCK" | head -1 | sed 's/.*": *"//;s/"//')
  if [ -n "$INSTALLED" ] && [ -n "$LOCKED" ] && [ "$INSTALLED" != "$LOCKED" ]; then
    echo "[G9] version mismatch: installed=$INSTALLED locked=$LOCKED"
    exit 1
  fi
fi

echo "[G9] passed"

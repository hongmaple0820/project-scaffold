#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[G16] Governance lock sync gate"

LOCK="$ROOT/.scale/governance.lock.json"
if [ ! -f "$LOCK" ]; then
  echo "[G16] no governance lock; skip"
  exit 0
fi

LOCKED_VERSION=$(grep -o '"scaleVersion": *"[^"]*"' "$LOCK" | head -1 | sed 's/.*": *"//;s/"//')
if [ -f "$ROOT/package.json" ]; then
  PACKAGE_VERSION=$(grep -o '"version": *"[^"]*"' "$ROOT/package.json" | head -1 | sed 's/.*": *"//;s/"//')
  if [ -n "$PACKAGE_VERSION" ] && [ -n "$LOCKED_VERSION" ] && [ "$PACKAGE_VERSION" != "$LOCKED_VERSION" ]; then
    echo "[G16] governance lock ($LOCKED_VERSION) != package ($PACKAGE_VERSION)"
    exit 1
  fi
fi

echo "[G16] passed"

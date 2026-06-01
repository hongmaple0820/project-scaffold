#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[G10] Governance lock drift check"

LOCK="$ROOT/.scale/governance.lock.json"
if [ ! -f "$LOCK" ]; then
  echo "[G10] no governance lock; skip"
  exit 0
fi

if ! command -v scale >/dev/null 2>&1; then
  echo "[G10] scale CLI not available; skip"
  exit 0
fi

DRIFT=$(cd "$ROOT" && scale upgrade check --dir . --json 2>/dev/null || echo '{}')
if echo "$DRIFT" | grep -q '"status":"local-changes"'; then
  echo "[G10] governance drift detected"
  exit 1
fi

echo "[G10] passed"

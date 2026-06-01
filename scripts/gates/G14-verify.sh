#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[G14] Resource hygiene gate"

JUNK=0
for pattern in "*.tmp" "*.bak" "*.orig" ".DS_Store" "Thumbs.db"; do
  count=$(find "$ROOT" -maxdepth 1 -name "$pattern" 2>/dev/null | wc -l)
  JUNK=$((JUNK + count))
done

if [ "$JUNK" -gt 0 ]; then
  echo "[G14] found $JUNK temporary files in project root"
  exit 1
fi

echo "[G14] passed"

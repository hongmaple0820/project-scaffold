#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[G17] Architecture consistency gate"

WS="$ROOT/.scale/workspace.json"
if [ ! -f "$WS" ]; then
  echo "[G17] no workspace.json; skip"
  exit 0
fi

MISSING=$(node -e "
  const fs = require('fs');
  const path = require('path');
  const ws = JSON.parse(fs.readFileSync(process.argv[1], 'utf-8'));
  const root = process.argv[2];
  let missing = 0;
  for (const repo of (ws.repositories || [])) {
    if (!repo.path || repo.path === '.') continue;
    const full = path.join(root, repo.path);
    if (!fs.existsSync(full)) {
      console.log('[G17] declared repo \"' + repo.name + '\" path not found: ' + repo.path);
      missing++;
    }
  }
  if (missing > 0) process.exit(1);
" "$WS" "$ROOT" 2>&1) || {
  echo "$MISSING"
  exit 1
}

echo "[G17] passed"

#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[ -f "$ROOT/docs/worklog/metrics.md" ] || { echo "metrics missing"; exit 1; }
echo "[G6] metrics file present"

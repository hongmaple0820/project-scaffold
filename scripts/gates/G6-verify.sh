#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
METRICS="$ROOT/docs/worklog/metrics.md"
STATE_FILE="$ROOT/.agent/state/current.json"
PY_STATE="$ROOT/scripts/lib/workflow_state.py"

[ -f "$METRICS" ] || { echo "[G6] metrics missing"; exit 1; }

grep -qE '^\| Date \| Task \| Level \|' "$METRICS" || {
  echo "[G6] metrics header missing or invalid"
  exit 1
}

DATA_ROWS=$(grep -cE '^\| [0-9]{4}-[0-9]{2}-[0-9]{2} \|' "$METRICS" || true)
if [ "$DATA_ROWS" -lt 1 ]; then
  echo "[G6] metrics has no task rows"
  exit 1
fi

if [ -f "$STATE_FILE" ]; then
  LEVEL=$(python3 "$PY_STATE" get "$STATE_FILE" level "")
  ARTIFACTS=$(python3 "$PY_STATE" get "$STATE_FILE" artifacts_dir "")
  case "$LEVEL" in
    M|L|CRITICAL)
      if [ -z "$ARTIFACTS" ] || [ ! -d "$ROOT/$ARTIFACTS" ]; then
        echo "[G6] M/L task artifacts_dir missing"
        exit 1
      fi
      for file in explore.md plan.md verification.md review.md summary.md; do
        if [ ! -f "$ROOT/$ARTIFACTS/$file" ]; then
          echo "[G6] missing task artifact: $file"
          exit 1
        fi
      done
      ;;
  esac
fi

echo "[G6] metrics and task artifacts present"

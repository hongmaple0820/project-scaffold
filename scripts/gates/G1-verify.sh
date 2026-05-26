#!/usr/bin/env bash
# Verify exploration state: at least three files and one main conflict.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"
MIN_FILES="${MIN_EXPLORE_FILES:-3}"

echo "========================================"
echo "[G1] Explore gate"
echo "========================================"

if [ ! -f "$STATE_FILE" ]; then
  echo "[G1] missing state file: .agent/state/current.json"
  echo "[G1] run: bash scripts/workflow/new-task.sh <task> M"
  echo "[G1] then: bash scripts/workflow/explore.sh <file...> \"main conflict\""
  exit 1
fi

if [ ! -f "$PY_STATE" ]; then
  echo "[G1] missing helper: scripts/lib/workflow_state.py"
  exit 1
fi

FILE_COUNT="$(python3 "$PY_STATE" get "$STATE_FILE" file_count 0 2>/dev/null || echo 0)"
CONTRADICTION="$(python3 "$PY_STATE" get "$STATE_FILE" main_contradiction "" 2>/dev/null || true)"

if [ "${FILE_COUNT:-0}" -lt "$MIN_FILES" ]; then
  echo "[G1] insufficient explored files: ${FILE_COUNT:-0} < $MIN_FILES"
  exit 1
fi

if [ -z "$CONTRADICTION" ]; then
  echo "[G1] missing main_contradiction"
  exit 1
fi

echo "[G1] passed"
echo "[G1] files: $FILE_COUNT"
echo "[G1] main contradiction: $CONTRADICTION"

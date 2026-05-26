#!/bin/bash
# Save current workflow phase into .agent/state/current.json.
# Usage: bash scripts/workflow/checkpoint.sh [phase]

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.agent/state"
OUTPUT="$STATE_DIR/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"

mkdir -p "$STATE_DIR"

PHASE="${1:-unknown}"
python3 "$PY_STATE" checkpoint "$OUTPUT" "$PROJECT_ROOT" "$PHASE"

echo "[CHECKPOINT] saved phase=$PHASE"
echo "[CHECKPOINT] state: $OUTPUT"

#!/bin/bash
# Record explore-phase evidence into the canonical workflow state.
# Usage: bash scripts/workflow/explore.sh "file1.go" "file2.md" "main conflict"

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.agent/state"
STATE_FILE="$STATE_DIR/current.json"
EXPLORE_FILE="$STATE_DIR/explore.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"

mkdir -p "$STATE_DIR"

FILES=("$@")
if [ ${#FILES[@]} -eq 0 ]; then
    echo "[EXPLORE] usage: bash scripts/workflow/explore.sh file1.go file2.md \"main conflict\""
    exit 1
fi

CONTRADICTION=""
REAL_FILES=()
for f in "${FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$f" ]; then
        REAL_FILES+=("$f")
    else
        CONTRADICTION="$f"
    fi
done

python3 "$PY_STATE" explore "$STATE_FILE" "$EXPLORE_FILE" "$CONTRADICTION" "${REAL_FILES[@]}"

echo "[EXPLORE] recorded ${#REAL_FILES[@]} files"
echo "[EXPLORE] main contradiction: ${CONTRADICTION:-not set}"
echo "[EXPLORE] state: $STATE_FILE"
echo "[EXPLORE] detail: $EXPLORE_FILE"

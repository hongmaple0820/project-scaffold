#!/bin/bash
# Create a standard workflow task directory and canonical state.
# Usage: bash scripts/workflow/new-task.sh "task-slug" [S|M|L|CRITICAL]

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAME="${1:-}"
LEVEL="${2:-M}"

if [ -z "$NAME" ]; then
    echo "[NEW-TASK] usage: bash scripts/workflow/new-task.sh \"task-slug\" [S|M|L|CRITICAL]"
    exit 1
fi

case "$LEVEL" in
    S|M|L|CRITICAL) ;;
    *)
        echo "[NEW-TASK] invalid level: $LEVEL"
        exit 1
        ;;
esac

DATE="$(date +%Y-%m-%d)"
TASK_ID="${DATE}-${NAME}"
TASK_DIR="$PROJECT_ROOT/.planning/tasks/$TASK_ID"
TEMPLATE_DIR="$PROJECT_ROOT/docs/workflow/templates"
STATE_DIR="$PROJECT_ROOT/.agent/state"
STATE_FILE="$STATE_DIR/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"

mkdir -p "$TASK_DIR" "$STATE_DIR"

for file in explore.md mini-prd.md plan.md runtime.md reality-check.md resource-cleanup.md verification.md review.md summary.md; do
    if [ ! -f "$TASK_DIR/$file" ]; then
        if [ -f "$TEMPLATE_DIR/$file" ]; then
            sed "s/{{TASK_ID}}/$TASK_ID/g; s/{{NAME}}/$NAME/g; s/{{DATE}}/$DATE/g; s/{{LEVEL}}/$LEVEL/g" "$TEMPLATE_DIR/$file" > "$TASK_DIR/$file"
        else
            cat > "$TASK_DIR/$file" << EOF
# ${file%.md} - $TASK_ID

Level: $LEVEL

EOF
        fi
    fi
done

python3 "$PY_STATE" init "$STATE_FILE" "$TASK_ID" "$LEVEL" ".planning/tasks/$TASK_ID"

echo "[NEW-TASK] created: $TASK_DIR"
echo "[NEW-TASK] state: $STATE_FILE"
echo "[NEW-TASK] next: fill explore.md, runtime.md, and reality-check.md before execution"

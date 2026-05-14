#!/bin/bash
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAME="${1:-}"
LEVEL="${2:-M}"
if [ -z "$NAME" ]; then
  echo "usage: bash scripts/workflow/new-task.sh task-slug [S|M|L|CRITICAL]"
  exit 1
fi
case "$LEVEL" in S|M|L|CRITICAL) ;; *) echo "invalid level: $LEVEL"; exit 1 ;; esac
DATE="$(date +%Y-%m-%d)"
TASK_ID="$DATE-$NAME"
TASK_DIR="$PROJECT_ROOT/docs/worklog/tasks/$TASK_ID"
STATE_DIR="$PROJECT_ROOT/.agent/state"
STATE_FILE="$STATE_DIR/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"
mkdir -p "$TASK_DIR" "$STATE_DIR"
for file in explore.md mini-prd.md plan.md verification.md review.md summary.md; do
  target="$TASK_DIR/$file"
  if [ ! -f "$target" ]; then
    if [ "$file" = "plan.md" ]; then
      cat > "$target" << EOF
# plan - $TASK_ID

Date: $DATE
Level: $LEVEL

## Scope / 范围

- 待填写。

## Boundary / 边界

- 待填写。

## Acceptance Criteria / 验收标准

- 待填写。

## Risks / 风险

- 待填写。

## Rollback / 回滚方案

- 待填写。

## Verification / 验证

- 待填写。

EOF
    else
      cat > "$target" << EOF
# ${file%.md} - $TASK_ID

Date: $DATE
Level: $LEVEL

## Notes

EOF
    fi
  fi
done
python3 "$PY_STATE" init "$STATE_FILE" "$TASK_ID" "$LEVEL" "docs/worklog/tasks/$TASK_ID"
echo "[NEW-TASK] created: $TASK_DIR"
echo "[NEW-TASK] state: $STATE_FILE"

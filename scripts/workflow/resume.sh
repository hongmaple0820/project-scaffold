#!/bin/bash
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"
if [ ! -f "$STATE_FILE" ]; then
  echo "[RESUME] no workflow state"
  exit 0
fi
for key in task_id level phase updated_at artifacts_dir explored_files main_contradiction completed_gates open_tasks files_modified; do
  value=$(python3 "$PY_STATE" get "$STATE_FILE" "$key" "")
  printf "%-20s %s\n" "$key:" "$value"
done

TASK_ID=$(python3 "$PY_STATE" get "$STATE_FILE" task_id "")
PHASE=$(python3 "$PY_STATE" get "$STATE_FILE" phase "")
ARTIFACTS=$(python3 "$PY_STATE" get "$STATE_FILE" artifacts_dir "")

echo ""
case "$PHASE" in
  explore)
    echo "next: fill $ARTIFACTS/plan.md, then run make gate-workflow"
    ;;
  plan)
    echo "next: execute $ARTIFACTS/plan.md, then run make checkpoint PHASE=execute"
    ;;
  execute)
    echo "next: run make gate-quality and update $ARTIFACTS/verification.md"
    ;;
  verify)
    echo "next: update $ARTIFACTS/review.md, $ARTIFACTS/summary.md, and docs/worklog/metrics.md"
    ;;
  done)
    echo "next: review final diff and prepare handoff"
    ;;
  *)
    echo "next: inspect current task ${TASK_ID:-unknown} and choose the next workflow phase"
    ;;
esac

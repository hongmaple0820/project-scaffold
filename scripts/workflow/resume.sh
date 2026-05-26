#!/bin/bash
# Show current workflow state from .agent/state/current.json.

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"

if [ ! -f "$STATE_FILE" ]; then
    echo "[RESUME] no workflow state; start with scripts/workflow/new-task.sh or explore.sh"
    exit 0
fi

PHASE=$(python3 "$PY_STATE" get "$STATE_FILE" phase unknown)
TASK_ID=$(python3 "$PY_STATE" get "$STATE_FILE" task_id unknown)
LEVEL=$(python3 "$PY_STATE" get "$STATE_FILE" level unknown)
ARTIFACTS_DIR=$(python3 "$PY_STATE" get "$STATE_FILE" artifacts_dir "")
RUNTIME_CONTRACT=$(python3 "$PY_STATE" get "$STATE_FILE" runtime_contract "")
REALITY_CHECK=$(python3 "$PY_STATE" get "$STATE_FILE" reality_check "")
RESOURCE_CLEANUP=$(python3 "$PY_STATE" get "$STATE_FILE" resource_cleanup "")
TIMESTAMP=$(python3 "$PY_STATE" get "$STATE_FILE" updated_at unknown)
GATES=$(python3 "$PY_STATE" get "$STATE_FILE" completed_gates "")
TASKS=$(python3 "$PY_STATE" get "$STATE_FILE" open_tasks "")
FILES=$(python3 "$PY_STATE" get "$STATE_FILE" files_modified "")
EXPLORED=$(python3 "$PY_STATE" get "$STATE_FILE" explored_files "")
CONTRADICTION=$(python3 "$PY_STATE" get "$STATE_FILE" main_contradiction "")

echo "[RESUME] workflow state:"
echo ""
echo "  task:        $TASK_ID"
echo "  level:       $LEVEL"
echo "  phase:       $PHASE"
echo "  updated:     $TIMESTAMP"
echo "  artifacts:   ${ARTIFACTS_DIR:-none}"
echo "  runtime:     ${RUNTIME_CONTRACT:-none}"
echo "  reality:     ${REALITY_CHECK:-none}"
echo "  cleanup:     ${RESOURCE_CLEANUP:-none}"
echo "  explored:    ${EXPLORED:-none}"
echo "  conflict:    ${CONTRADICTION:-none}"
echo "  gates:       ${GATES:-none}"
echo "  open tasks:  ${TASKS:-none}"
echo "  modified:    ${FILES:-none}"
echo ""

case "$PHASE" in
    explore)
        echo "[RESUME] next: complete explore.md, then run plan.sh or move to plan"
        ;;
    plan)
        echo "[RESUME] next: complete plan.md; L/CRITICAL work needs confirmation before execution"
        ;;
    execute)
        echo "[RESUME] next: continue implementation and keep verification notes current"
        ;;
    verify)
        echo "[RESUME] next: run scripts/workflow/verify.sh all or scripts/gates/all.sh --quality"
        ;;
    consolidate)
        echo "[RESUME] next: complete review.md, summary.md, and metrics row"
        ;;
    *)
        echo "[RESUME] next: start from explore"
        ;;
esac

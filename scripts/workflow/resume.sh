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

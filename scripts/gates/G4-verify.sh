#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS=(
  "$ROOT/scripts/gates/all.sh"
  "$ROOT/scripts/gates/G1-verify.sh"
  "$ROOT/scripts/gates/G2-verify.sh"
  "$ROOT/scripts/gates/G3-verify.sh"
  "$ROOT/scripts/gates/G4-verify.sh"
  "$ROOT/scripts/gates/G5-verify.sh"
  "$ROOT/scripts/gates/G6-verify.sh"
  "$ROOT/scripts/gates/G7-verify.sh"
  "$ROOT/scripts/preflight/all.sh"
  "$ROOT/scripts/workflow/new-task.sh"
  "$ROOT/scripts/workflow/explore.sh"
  "$ROOT/scripts/workflow/plan.sh"
  "$ROOT/scripts/workflow/checkpoint.sh"
  "$ROOT/scripts/workflow/resume.sh"
)
for script in "${SCRIPTS[@]}"; do
  bash -n "$script"
done
python3 -m py_compile "$ROOT/scripts/lib/workflow_state.py"
echo "[G4] scaffold scripts passed"

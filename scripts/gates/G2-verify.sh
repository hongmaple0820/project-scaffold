#!/bin/bash
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"
ARTIFACTS=$(python3 "$PY_STATE" get "$STATE_FILE" artifacts_dir "" 2>/dev/null || true)
if [ -z "$ARTIFACTS" ]; then
  echo "artifacts_dir missing in .agent/state/current.json"
  exit 1
fi
PLAN="$PROJECT_ROOT/$ARTIFACTS/plan.md"
if [ ! -f "$PLAN" ]; then echo "missing plan artifact: $PLAN"; exit 1; fi
grep -qiE "scope|范围" "$PLAN" || { echo "plan missing scope"; exit 1; }
grep -qiE "boundary|边界" "$PLAN" || { echo "plan missing boundary"; exit 1; }
grep -qiE "acceptance|验收" "$PLAN" || { echo "plan missing acceptance criteria"; exit 1; }
echo "[G2] passed"

#!/bin/bash
# checkpoint.sh — 保存工作流状态
# 用法: bash scripts/workflow/checkpoint.sh [phase]
# 产出: .agent/state/current.json

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.agent/state"
OUTPUT="$STATE_DIR/current.json"

mkdir -p "$STATE_DIR"

PHASE="${1:-unknown}"

# 收集已通过的门控
COMPLETED_GATES="[]"
if [ -f "$OUTPUT" ]; then
    COMPLETED_GATES=$(jq -r '.completed_gates // []' "$OUTPUT" 2>/dev/null || echo "[]")
fi

# 收集修改过的文件（如果有 git）
FILES_MODIFIED="[]"
if [ -d "$PROJECT_ROOT/.git" ]; then
    FILES_MODIFIED=$(cd "$PROJECT_ROOT" && git diff --name-only 2>/dev/null | jq -R . | jq -s . || echo "[]")
fi

# 收集未完成任务
OPEN_TASKS="[]"
if [ -f "$OUTPUT" ]; then
    OPEN_TASKS=$(jq -r '.open_tasks // []' "$OUTPUT" 2>/dev/null || echo "[]")
fi

# 写入状态
cat > "$OUTPUT" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "phase": "$PHASE",
  "completed_gates": $COMPLETED_GATES,
  "open_tasks": $OPEN_TASKS,
  "files_modified": $FILES_MODIFIED
}
EOF

echo "[CHECKPOINT] ✅ 已保存状态: phase=$PHASE"
echo "[CHECKPOINT] 产物: $OUTPUT"

#!/bin/bash
# resume.sh — 恢复工作流状态
# 用法: bash scripts/workflow/resume.sh
# 读取: .agent/state/current.json

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"

if [ ! -f "$STATE_FILE" ]; then
    echo "[RESUME] ℹ️ 无历史状态，从 idle 开始"
    exit 0
fi

PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null)
TIMESTAMP=$(jq -r '.timestamp // "unknown"' "$STATE_FILE" 2>/dev/null)
GATES=$(jq -r '.completed_gates // [] | join(", ")' "$STATE_FILE" 2>/dev/null)
TASKS=$(jq -r '.open_tasks // [] | join(", ")' "$STATE_FILE" 2>/dev/null)
FILES=$(jq -r '.files_modified // [] | join(", ")' "$STATE_FILE" 2>/dev/null)

echo "[RESUME] 检测到之前的状态:"
echo ""
echo "  阶段:     $PHASE"
echo "  时间:     $TIMESTAMP"
echo "  已通过:   ${GATES:-无}"
echo "  未完成:   ${TASKS:-无}"
echo "  已修改:   ${FILES:-无}"
echo ""

case "$PHASE" in
    explore)
        echo "[RESUME] 建议: 继续探索，或运行 plan.sh 进入规划阶段"
        ;;
    plan)
        echo "[RESUME] 建议: 完善计划，L级任务需人工确认后继续"
        ;;
    execute)
        echo "[RESUME] 建议: 继续执行，注意 TDD（先写测试）"
        ;;
    verify)
        echo "[RESUME] 建议: 运行 bash scripts/gates/all.sh 验证"
        ;;
    consolidate)
        echo "[RESUME] 建议: 泛化检查 + 文档更新 + 图谱更新"
        ;;
    *)
        echo "[RESUME] 未知阶段，建议从探索开始"
        ;;
esac

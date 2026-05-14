#!/bin/bash
# G1-verify.sh — 探索阶段验证（检查 explore.sh 产出的真实产物）
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXPLORE_FILE="$PROJECT_ROOT/.agent/state/explore.json"
ERRORS=0

echo "[G1] 探索阶段验证..."

# 检查1: 探索记录是否存在（由 explore.sh 产出）
if [ ! -f "$EXPLORE_FILE" ]; then
    echo "[G1] ❌ 缺少探索记录: $EXPLORE_FILE"
    echo "[G1] 运行: bash scripts/workflow/explore.sh file1.go file2.go '主要矛盾'"
    exit 1
fi

# 检查2: 文件数量 ≥ 3
FILE_COUNT=$(jq -r '.file_count // 0' "$EXPLORE_FILE" 2>/dev/null)
if [ "$FILE_COUNT" -lt 3 ]; then
    echo "[G1] ❌ 只读了 $FILE_COUNT 个文件，需要 ≥ 3"
    ERRORS=$((ERRORS+1))
else
    echo "[G1] ✅ 已读 $FILE_COUNT 个文件"
fi

# 检查3: 主要矛盾是否已识别
CONTRADICTION=$(jq -r '.main_contradiction // ""' "$EXPLORE_FILE" 2>/dev/null)
if [ -z "$CONTRADICTION" ]; then
    echo "[G1] ⚠️ 未识别主要矛盾（建议但非必须）"
else
    echo "[G1] ✅ 主要矛盾: $CONTRADICTION"
fi

# 检查4: 知识图谱（可选）
GRAPHIFY=$(jq -r '.graphify_read // false' "$EXPLORE_FILE" 2>/dev/null)
if [ "$GRAPHIFY" = "true" ]; then
    NODES=$(jq -r '.graph_nodes // 0' "$EXPLORE_FILE" 2>/dev/null)
    echo "[G1] ✅ 知识图谱已读: $NODES 节点"
else
    echo "[G1] ℹ️ 未读知识图谱（可选: graphify .）"
fi

if [ $ERRORS -gt 0 ]; then
    exit 1
fi
echo "[G1] ✅ 探索阶段验证通过"
exit 0

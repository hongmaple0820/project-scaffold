#!/bin/bash
# explore.sh — 记录探索阶段产物
# 用法: bash scripts/workflow/explore.sh "file1.go" "file2.go" "主要矛盾描述"
# 产出: .agent/state/explore.json

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.agent/state"
OUTPUT="$STATE_DIR/explore.json"

mkdir -p "$STATE_DIR"

# 收集参数
FILES=("$@")
if [ ${#FILES[@]} -eq 0 ]; then
    echo "[EXPLORE] 用法: bash scripts/workflow/explore.sh file1.go file2.go [主要矛盾]"
    echo "[EXPLORE] 列出你读过的文件，最后一个参数可选为主要矛盾描述"
    exit 1
fi

# 最后一个参数如果是非文件路径，当作主要矛盾
CONTRADICTION=""
REAL_FILES=()
for f in "${FILES[@]}"; do
    if [[ "$f" == *".go"* || "$f" == *".md"* || "$f" == *".yaml"* || "$f" == *".json"* || "$f" == *".api"* || "$f" == *".sql"* || -f "$PROJECT_ROOT/$f" ]]; then
        REAL_FILES+=("$f")
    else
        CONTRADICTION="$f"
    fi
done

# 检查知识图谱
GRAPHIFY="false"
if [ -f "$PROJECT_ROOT/graphify-out/graph.json" ]; then
    GRAPHIFY="true"
    GRAPH_NODES=$(jq '.nodes | length' "$PROJECT_ROOT/graphify-out/graph.json" 2>/dev/null || echo "0")
fi

# 写入探索记录
cat > "$OUTPUT" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "files": $(printf '%s\n' "${REAL_FILES[@]}" | jq -R . | jq -s .),
  "file_count": ${#REAL_FILES[@]},
  "graphify_read": $GRAPHIFY,
  "graph_nodes": ${GRAPH_NODES:-0},
  "main_contradiction": "$CONTRADICTION",
  "skills_checked": true
}
EOF

echo "[EXPLORE] ✅ 已记录探索结果: ${#REAL_FILES[@]} 个文件"
if [ -n "$CONTRADICTION" ]; then
    echo "[EXPLORE] 主要矛盾: $CONTRADICTION"
fi
if [ "$GRAPHIFY" = "true" ]; then
    echo "[EXPLORE] 知识图谱: $GRAPH_NODES 节点"
fi
echo "[EXPLORE] 产物: $OUTPUT"

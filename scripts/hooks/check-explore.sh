#!/bin/bash
# check-explore.sh — 写 .go 文件前检查探索产物
# 设计: 如果还没有运行 explore.sh，强烈提醒先探索
# 这是工作流的核心强制机制

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
EXPLORE_FILE="$PROJECT_ROOT/.agent/state/explore.json"

if [ ! -f "$EXPLORE_FILE" ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  [WORKFLOW] 尚未完成探索阶段                                    ║"
    echo "║  ────────────────────────────────────────────────────────── ║"
    echo "║  写代码前必须先探索。运行:                                      ║"
    echo "║                                                              ║"
    echo "║    bash scripts/workflow/explore.sh file1.go file2.go '矛盾'  ║"
    echo "║                                                              ║"
    echo "║  或读取: CLAUDE.md + graphify-out/GRAPH_REPORT.md + 相关代码    ║"
    echo "║  然后运行 explore.sh 记录探索结果                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    # exit 0 = 警告但不阻断（S级任务可以直接做）
    # 如果要硬阻断，改为 exit 2
    exit 0
fi

# 探索文件存在，检查文件数量
FILE_COUNT=$(jq -r '.file_count // 0' "$EXPLORE_FILE" 2>/dev/null)
if [ "$FILE_COUNT" -lt 3 ]; then
    echo "[WORKFLOW] ⚠️ 探索只读了 $FILE_COUNT 个文件（建议 ≥ 3）"
fi

exit 0

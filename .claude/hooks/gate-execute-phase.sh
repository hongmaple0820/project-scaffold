#!/bin/bash
# .claude/hooks/gate-execute-phase.sh
# G2: 执行阶段门控（脚手架项目）
# 触发: PreToolUse Write|Edit
# 功能: 检查 EXPLORE 和 PLAN 阶段完成标记
# 返回: 0=通过, 2=阻断

SESSION_DIR=".claude/session"
STATE_FILE="$SESSION_DIR/.flow-state"

# 检查状态文件是否存在
if [[ ! -f "$STATE_FILE" ]]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  [GATE BLOCK] 认知工作流未启动                            ║"
    echo "║  ────────────────────────────────────────────────────────║"
    echo "║  M/L级任务必须先执行探索和规划阶段                         ║"
    echo "║                                                          ║"
    echo "║  阶段输出规范:                                            ║"
    echo "║    [EXPLORE] ✓ CLAUDE.md ✓ | 图谱 ✓ | 技能 ✓             ║"
    echo "║    [PLAN] ✓ 影响面 ✓ | 契约 ✓ | 方案 ✓                   ║"
    echo "║                                                          ║"
    echo "║  每阶段完成后写入状态文件:                                ║"
    echo "║    EXPLORE=✓                                              ║"
    echo "║    PLAN=✓                                                 ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    exit 2
fi

# 检查 EXPLORE 阶段完成
if ! grep -q "EXPLORE=✓" "$STATE_FILE" 2>/dev/null; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  [GATE BLOCK] 探索阶段未完成                              ║"
    echo "║  ────────────────────────────────────────────────────────║"
    echo "║  必须完成探索阶段才能写代码:                               ║"
    echo "║                                                          ║"
    echo "║  探索阶段检查项:                                          ║"
    echo "║    ✓ 读取 CLAUDE.md                                       ║"
    echo "║    ✓ 检查 graphify-out/GRAPH_REPORT.md（如有）           ║"
    echo "║    ✓ 扫描相关代码文件                                     ║"
    echo "║    ✓ 矛盾分析（抓主要矛盾）                                ║"
    echo "║    ✓ 技能清单确认                                         ║"
    echo "║                                                          ║"
    echo "║  完成后输出:                                              ║"
    echo "║    [EXPLORE] ✓ 检查项 ✓ | ...                             ║"
    echo "║    并更新状态文件: EXPLORE=✓                              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    exit 2
fi

# 检查 PLAN 阶段完成
if ! grep -q "PLAN=✓" "$STATE_FILE" 2>/dev/null; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  [GATE BLOCK] 规划阶段未完成                              ║"
    echo "║  ────────────────────────────────────────────────────────║"
    echo "║  必须完成规划阶段才能写代码:                               ║"
    echo "║                                                          ║"
    echo "║  规划阶段检查项:                                          ║"
    echo "║    ✓ 影响面推理（会影响哪些模块？）                       ║"
    echo "║    ✓ 契约定义（功能边界 + 异常契约）                      ║"
    echo "║    ✓ 方案输出                                             ║"
    echo "║                                                          ║"
    echo "║  完成后输出:                                              ║"
    echo "║    [PLAN] ✓ 检查项 ✓ | ...                                ║"
    echo "║    并更新状态文件: PLAN=✓                                 ║"
    echo "║                                                          ║"
    echo "║  ⚠️ L级任务: 规划完成后必须人工确认才能继续               ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    exit 2
fi

exit 0
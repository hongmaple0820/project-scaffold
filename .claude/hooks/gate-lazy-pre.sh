#!/bin/bash
# .claude/hooks/gate-lazy-pre.sh
# G3: 懒惰模式阻断（前置）
# 触发: PreToolUse（所有工具）
# 功能: 检测即将发生的懒惰行为并阻断
# 返回: 0=通过, 2=阻断

SESSION_DIR=".claude/session"
FAIL_COUNT_FILE="$SESSION_DIR/.fail-count"

# 检查失败计数
if [[ -f "$FAIL_COUNT_FILE" ]]; then
    FAIL_COUNT=$(cat "$FAIL_COUNT_FILE" 2>/dev/null || echo "0")

    if [[ "$FAIL_COUNT" -ge 3 ]]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║  [GATE BLOCK] 暴力重试检测                                ║"
        echo "║  ────────────────────────────────────────────────────────║"
        echo "║  连续失败 $FAIL_COUNT 次，已触发暴力重试阻断               ║"
        echo "║                                                          ║"
        echo "║  反制措施:                                                ║"
        echo "║    1. 停止当前策略                                        ║"
        echo "║    2. 回到探索阶段，重新分析问题                           ║"
        echo "║    3. 换一种完全不同的实现思路                             ║"
        echo "║    4. 调用 systematic-debugging 技能                      ║"
        echo "║                                                          ║"
        echo "║  建议: 清空失败计数后重新尝试                              ║"
        echo "║    rm .claude/session/.fail-count                        ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        exit 2
    fi
fi

exit 0
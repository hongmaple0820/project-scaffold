#!/bin/bash
# .claude/hooks/detect-lazy-post.sh
# G4: 懒惰模式检测（后置）
# 触发: PostToolUse（所有工具）
# 功能: 检测已发生的懒惰行为并记录
# 返回: 0=通过（仅记录，不阻断）

SESSION_DIR=".claude/session"
FAIL_COUNT_FILE="$SESSION_DIR/.fail-count"
LAZY_MARKER="$SESSION_DIR/.lazy-detected"
TOOL_HISTORY="$SESSION_DIR/.tool-history"

# 创建目录
mkdir -p "$SESSION_DIR"

# 检测失败计数增加（通过工具结果判断）
# 如果工具调用失败，增加计数
if [[ -n "$CLAUDE_TOOL_RESULT" ]]; then
    if echo "$CLAUDE_TOOL_RESULT" | grep -qiE "error|fail|failed|exception"; then
        CURRENT_COUNT=$(cat "$FAIL_COUNT_FILE" 2>/dev/null || echo "0")
        NEW_COUNT=$((CURRENT_COUNT + 1))
        echo "$NEW_COUNT" > "$FAIL_COUNT_FILE"

        if [[ "$NEW_COUNT" -ge 2 ]]; then
            echo "[LAZY WARNING] 连续失败 $NEW_COUNT 次，接近暴力重试阈值"
            echo "timestamp=$(date -Iseconds)" >> "$LAZY_MARKER"
        fi
    else
        # 成功则清空失败计数
        echo "0" > "$FAIL_COUNT_FILE"
    fi
fi

# 记录工具调用历史（用于忙碌假象检测）
TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TIMESTAMP=$(date -Iseconds)
echo "$TIMESTAMP|$TOOL_NAME" >> "$TOOL_HISTORY"

# 检测忙碌假象：最近10次调用是否有实质变化
if [[ -f "$TOOL_HISTORY" ]]; then
    RECENT_CALLS=$(tail -10 "$TOOL_HISTORY" 2>/dev/null)
    UNIQUE_TOOLS=$(echo "$RECENT_CALLS" | cut -d'|' -f2 | sort | uniq | wc -l)

    if [[ "$UNIQUE_TOOLS" -le 2 ]]; then
        echo "[LAZY WARNING] 工具调用单调（$UNIQUE_TOOLS 种），可能陷入忙碌假象"
        echo "建议: 换工具/换策略/停下来重新分析"
    fi
fi

exit 0
#!/bin/bash
# .claude/hooks/detect-context-pollution.sh
# G5: 上下文污染检测
# 触发: PostToolUse Write|Edit|Bash
# 功能: 检测上下文是否被失败方案污染
# 返回: 0=通过, 2=阻断并标记污染

SESSION_DIR=".claude/session"
FAIL_COUNT_FILE="$SESSION_DIR/.fail-count"
POLLUTION_MARKER="$SESSION_DIR/.pollution-detected"

# 检查失败计数
if [[ -f "$FAIL_COUNT_FILE" ]]; then
    FAIL_COUNT=$(cat "$FAIL_COUNT_FILE" 2>/dev/null || echo "0")

    # 修正两次后判定上下文污染
    if [[ "$FAIL_COUNT" -ge 2 ]]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║  [POLLUTION WARNING] 上下文已被失败方案污染               ║"
        echo "║  ────────────────────────────────────────────────────────║"
        echo "║  连续修正失败 $FAIL_COUNT 次                              ║"
        echo "║                                                          ║"
        echo "║  建议:                                                    ║"
        echo "║    1. 建议用户清空上下文 (/clear)                         ║"
        echo "║    2. 用融合了前两轮教训的更好提示词重新开始              ║"
        echo "║    3. 干净会话 + 好提示词 > 长会话 + 反复修正             ║"
        echo "║                                                          ║"
        echo "║  当前状态已标记为污染，需人工清理后才能继续               ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""

        # 写入污染标记
        mkdir -p "$SESSION_DIR"
        echo "POLLUTION=1" > "$POLLUTION_MARKER"
        echo "timestamp=$(date -Iseconds)" >> "$POLLUTION_MARKER"
        echo "fail_count=$FAIL_COUNT" >> "$POLLUTION_MARKER"

        exit 0  # 不阻断，仅警告
    fi
fi

exit 0
#!/bin/bash
# .claude/hooks/session-end-gate.sh
# G6: 会话结束门控（脚手架项目）
# 触发: Stop
# 功能: 检查所有阶段完成 + 验证标记 + 污染检查
# 返回: 0=通过并清理, 2=阻断

STATE_FILE=".claude/session/.flow-state"
VERIFY_MARKER=".claude/session/.verified"
POLLUTION_MARKER=".claude/session/.pollution-detected"

# 检查污染标记
if [[ -f "$POLLUTION_MARKER" ]]; then
    if grep -q "POLLUTION=1" "$POLLUTION_MARKER"; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║  [GATE BLOCK] 上下文污染未清理                            ║"
        echo "║  ────────────────────────────────────────────────────────║"
        echo "║  修正 ≥2 次失败后上下文被污染                              ║"
        echo "║  必须执行 /clear 或输出 [POLLUTION CLEARED]                ║"
        echo "║                                                          ║"
        echo "║  建议: 检查 scripts/gates/ 是否有相关门控脚本             ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        exit 2
    fi
fi

# 检查验证标记
if [[ ! -f "$VERIFY_MARKER" ]]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  [GATE BLOCK] 验证未完成                                  ║"
    echo "║  ────────────────────────────────────────────────────────║"
    echo "║  声称完成前必须执行验证:                                   ║"
    echo "║    1. 调用 verification skill                             ║"
    echo "║    2. 运行 make test 或 make gate                         ║"
    echo "║    3. 输出 [VERIFY] ✓ 检查项 ✓ | ...                       ║"
    echo "║                                                          ║"
    echo "║  可用验证命令:                                            ║"
    echo "║    • make lint    — G4 门控                               ║"
    echo "║    • make test    — G5 门控                               ║"
    echo "║    • make coverage — G6 门控                              ║"
    echo "║    • make gate    — 所有门控                              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    exit 2
fi

# 检查状态文件
if [[ ! -f "$STATE_FILE" ]]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  [GATE BLOCK] 认知工作流未执行                            ║"
    echo "║  ────────────────────────────────────────────────────────║"
    echo "║  M/L 级任务必须执行完整5阶段流程                           ║"
    echo "║                                                          ║"
    echo "║  [SKILL SCAN] ✓ 技能清单                                  ║"
    echo "║  [EXPLORE] ✓ 探索阶段                                     ║"
    echo "║  [PLAN] ✓ 规划阶段                                        ║"
    echo "║  [EXECUTE] ✓ 执行阶段                                     ║"
    echo "║  [VERIFY] ✓ 验证阶段                                      ║"
    echo "║  [SETTLE] ✓ 沉淀阶段                                      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    exit 2
fi

# 检查所有5阶段完成
PHASES="SKILL_SCAN EXPLORE PLAN EXECUTE VERIFY SETTLE"
MISSING_PHASES=""

for phase in $PHASES; do
    if ! grep -q "${phase}=✓" "$STATE_FILE"; then
        MISSING_PHASES="$MISSING_PHASES $phase"
    fi
done

if [[ -n "$MISSING_PHASES" ]]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  [GATE BLOCK] 认知工作流未完成                            ║"
    echo "║  ────────────────────────────────────────────────────────║"
    echo "║  缺失阶段: $MISSING_PHASES                                 ║"
    echo "║                                                          ║"
    echo "║  必须完成所有阶段才能结束会话                              ║"
    echo "║                                                          ║"
    echo "║  预期输出:                                                ║"
    echo "║  [SKILL SCAN] ✓ 技能1 ✓ | 技能2 ✓ | ...                   ║"
    echo "║  [EXPLORE] ✓ CLAUDE.md ✓ | 图谱 ✓ | 技能 ✓                ║"
    echo "║  [PLAN] ✓ 影响面 ✓ | 契约 ✓ | 方案 ✓                      ║"
    echo "║  [EXECUTE] ✓ TDD RED ✓ | GREEN ✓ | REFACTOR ✓             ║"
    echo "║  [VERIFY] ✓ Lint ✓ | Test ✓ | Coverage ✓                  ║"
    echo "║  [SETTLE] ✓ 泛化 ✓ | 文档 ✓ | 经验 ✓                      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    exit 2
fi

# 所有检查通过，清理状态文件
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  [GATE PASS] 认知工作流验证通过                           ║"
echo "║  ────────────────────────────────────────────────────────║"
echo "║  所有阶段已完成，清理状态文件                              ║"
echo "║                                                          ║"
echo "║  提醒:                                                    ║"
echo "║  - 脚手架模板已更新                                       ║"
echo "║  - 检查 scripts/gates/ 门控脚本                           ║"
echo "║  - 状态管理在 .agent/state/                               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 清理状态文件
rm -f "$STATE_FILE"
rm -f ".claude/session/.tool-history"
rm -f ".claude/session/.lazy-detected"
rm -f ".claude/session/.fail-count"
rm -f "$POLLUTION_MARKER"
rm -f "$VERIFY_MARKER"
rm -f ".claude/session/.skill-scanned"

exit 0
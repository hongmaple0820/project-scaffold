#!/bin/bash
# .claude/hooks/session-start-reminder.sh
# P1: 会话开始提醒（脚手架项目）
# 触发: SessionStart
# 功能: 输出技能清单提示和认知工作流要求
# 返回: 0=通过（软提醒，不阻断）

SESSION_DIR=".claude/session"

# 清理旧状态文件（新会话开始）
rm -f "$SESSION_DIR/.flow-state"
rm -f "$SESSION_DIR/.skill-scanned"
rm -f "$SESSION_DIR/.verified"
rm -f "$SESSION_DIR/.lazy-detected"
rm -f "$SESSION_DIR/.pollution-detected"
rm -f "$SESSION_DIR/.tool-history"
rm -f "$SESSION_DIR/.fail-count"

mkdir -p "$SESSION_DIR"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║            认知工作流提醒（脚手架项目）                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "=== 技能清单检查 ==="
echo ""
echo "必需技能:"
echo "  ├─ superpowers (brainstorming, tdd, verification)"
echo "  └─ graphify (代码知识图谱)"
echo ""
echo "推荐技能:"
echo "  └─ oh-my-claudecode (OMC 工作流增强)"
echo ""
echo "检查命令: ls ~/.claude/skills/"
echo "安装参考: CLAUDE.md §4"
echo ""
echo "=== 认知工作流要求 ==="
echo ""
echo "M/L级任务必须执行 5 阶段流程:"
echo ""
echo "  [SKILL SCAN] ✓ 技能清单"
echo "  [EXPLORE]    ✓ CLAUDE.md ✓ | 图谱 ✓ | 技能 ✓"
echo "  [PLAN]       ✓ 影响面 ✓ | 契约 ✓ | 方案 ✓"
echo "  [EXECUTE]    ✓ TDD RED ✓ | GREEN ✓ | REFACTOR ✓"
echo "  [VERIFY]     ✓ Lint ✓ | Test ✓ | Coverage ✓"
echo "  [SETTLE]     ✓ 泛化 ✓ | 文档 ✓ | 经验 ✓"
echo ""
echo "⚠️ 输出规范:"
echo "  每阶段完成必须输出结构化日志:"
echo "  [阶段名] ✓ 检查项1 ✓ | 检查项2 ✓ | ..."
echo ""
echo "=== 项目特性 ==="
echo ""
echo "本项目是脚手架模板:"
echo "  • 机器可执行 CLAUDE.md 格式"
echo "  • 门控脚本: scripts/gates/*.sh"
echo "  • 状态管理: .agent/state/"
echo "  • 知识图谱: graphify-out/"
echo ""
echo "=== 状态文件 ==="
echo ""
echo "状态文件位置: .claude/session/.flow-state"
echo "阶段完成后写入: SKILL_SCAN=✓, EXPLORE=✓, PLAN=✓, ..."
echo ""

exit 0
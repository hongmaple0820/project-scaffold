#!/bin/bash
# .claude/hooks/gate-skill-scan.sh
# G1: 技能扫描门控（脚手架项目）
# 触发: PreToolUse Write|Edit
# 功能: 检查技能扫描标记，未完成则阻断
# 返回: 0=通过, 2=阻断

SESSION_DIR=".claude/session"
SKILL_MARKER="$SESSION_DIR/.skill-scanned"

# 检查技能扫描标记
if [[ ! -f "$SKILL_MARKER" ]]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  [GATE BLOCK] 技能扫描未完成                              ║"
    echo "║  ────────────────────────────────────────────────────────║"
    echo "║  写代码前必须先扫描可用技能:                               ║"
    echo "║                                                          ║"
    echo "║  必需技能:                                                ║"
    echo "║    - superpowers (brainstorming, tdd, verification)      ║"
    echo "║    - graphify (代码知识图谱)                              ║"
    echo "║                                                          ║"
    echo "║  推荐技能:                                                ║"
    echo "║    - oh-my-claudecode (OMC 工作流增强)                   ║"
    echo "║                                                          ║"
    echo "║  执行步骤:                                                ║"
    echo "║    1. 检查已安装技能: ls ~/.claude/skills/                ║"
    echo "║    2. 缺失技能安装: 参考 CLAUDE.md §4                     ║"
    echo "║    3. 输出 [SKILL SCAN] ✓ 技能清单                        ║"
    echo "║    4. 创建标记: touch .claude/session/.skill-scanned     ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    exit 2
fi

exit 0
#!/bin/bash
# scripts/verify-config.sh
# 脚手架项目配置生成后自动验证
# 用法: bash scripts/verify-config.sh

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║            工作流配置验证（脚手架项目）                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

PROJECT_ROOT=$(pwd)
ERRORS=0
WARNINGS=0

# ─────────────────────────────────────────────────────────────
# 第一部分：Hook 脚本检查
# ─────────────────────────────────────────────────────────────

echo "=== [1/6] Hook 脚本检查 ==="

REQUIRED_HOOKS=(
    "gate-skill-scan"
    "gate-execute-phase"
    "detect-lazy-post"
    "gate-lazy-pre"
    "detect-context-pollution"
    "session-start-reminder"
    "session-end-gate"
)

for hook in "${REQUIRED_HOOKS[@]}"; do
    HOOK_PATH=".claude/hooks/${hook}.sh"

    if [[ ! -f "$HOOK_PATH" ]]; then
        echo "❌ Hook 缺失: ${hook}.sh"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    if [[ ! -x "$HOOK_PATH" ]]; then
        echo "⚠️ Hook 不可执行: ${hook}.sh (已自动修复)"
        chmod +x "$HOOK_PATH"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "✅ Hook 存在且可执行: ${hook}.sh"
    fi
done

echo ""

# ─────────────────────────────────────────────────────────────
# 第二部分：settings.json Hook 配置检查
# ─────────────────────────────────────────────────────────────

echo "=== [2/6] settings.json Hook 配置检查 ==="

SETTINGS_PATH=".claude/settings.json"

if [[ ! -f "$SETTINGS_PATH" ]]; then
    echo "❌ settings.json 不存在"
    ERRORS=$((ERRORS + 1))
else
    # 检查 SessionStart
    if ! grep -q "SessionStart" "$SETTINGS_PATH"; then
        echo "❌ settings.json 缺少 SessionStart Hook"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ SessionStart Hook 配置存在"
    fi

    # 检查 PreToolUse
    if ! grep -q "PreToolUse" "$SETTINGS_PATH"; then
        echo "❌ settings.json 缺少 PreToolUse Hook"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ PreToolUse Hook 配置存在"
    fi

    # 检查 PostToolUse
    if ! grep -q "PostToolUse" "$SETTINGS_PATH"; then
        echo "❌ settings.json 缺少 PostToolUse Hook"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ PostToolUse Hook 配置存在"
    fi

    # 检查 Stop
    if ! grep -q "Stop" "$SETTINGS_PATH"; then
        echo "❌ settings.json 缺少 Stop Hook"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ Stop Hook 配置存在"
    fi

    # 检查认知工作流特定命令
    if ! grep -q "gate-skill-scan" "$SETTINGS_PATH"; then
        echo "⚠️ settings.json 未配置 G1 技能扫描门控"
        WARNINGS=$((WARNINGS + 1))
    fi

    if ! grep -q "gate-execute-phase" "$SETTINGS_PATH"; then
        echo "⚠️ settings.json 未配置 G2 执行阶段门控"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""

# ─────────────────────────────────────────────────────────────
# 第三部分：AGENTS.md 核心内容检查
# ─────────────────────────────────────────────────────────────

echo "=== [3/6] AGENTS.md 核心内容检查 ==="

AGENTS_MD="AGENTS.md"

if [[ ! -f "$AGENTS_MD" ]]; then
    echo "❌ AGENTS.md 不存在"
    ERRORS=$((ERRORS + 1))
else
    REQUIRED_SECTIONS=(
        "反惰性警觉"
        "认知工作流"
        "绝对红线"
        "核心元认知"
        "质量门控"
    )

    for section in "${REQUIRED_SECTIONS[@]}"; do
        if grep -q "$section" "$AGENTS_MD"; then
            echo "✅ AGENTS.md 包含: $section"
        else
            echo "❌ AGENTS.md 缺少: $section"
            ERRORS=$((ERRORS + 1))
        fi
    done

    # 检查脚手架项目特有内容
    SCAFFOLD_SPECIFIC=(
        "机器可执行"
        "scripts/gates"
        "scripts/hooks"
        ".claude/session"
    )

    for item in "${SCAFFOLD_SPECIFIC[@]}"; do
        if grep -q "$item" "$AGENTS_MD"; then
            echo "✅ AGENTS.md 包含脚手架特有: $item"
        else
            echo "⚠️ AGENTS.md 缺少脚手架特有: $item"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
fi

echo ""

# ─────────────────────────────────────────────────────────────
# 第四部分：状态文件目录检查
# ─────────────────────────────────────────────────────────────

echo "=== [4/6] 状态文件目录检查 ==="

SESSION_DIR=".claude/session"

if [[ ! -d "$SESSION_DIR" ]]; then
    echo "⚠️ .claude/session 目录不存在 (已自动创建)"
    mkdir -p "$SESSION_DIR"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✅ .claude/session 目录存在"
fi

# 检查状态文件模板
STATE_TEMPLATE="${SESSION_DIR}/.flow-state.example"

if [[ ! -f "$STATE_TEMPLATE" ]]; then
    echo "⚠️ 状态文件模板不存在 (已自动创建)"
    cat > "$STATE_TEMPLATE" << 'EOF'
# 认知工作流状态文件示例
# 实际运行时由 Claude 输出阶段标记时自动写入

SKILL_SCAN=✓
EXPLORE=✓
PLAN=✓
EXECUTE=⏳
VERIFY=
SETTLE=
POLLUTION=
LAZY=
EOF
    WARNINGS=$((WARNINGS + 1))
else
    echo "✅ 状态文件模板存在"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# 第五部分：脚手架项目特有脚本检查
# ─────────────────────────────────────────────────────────────

echo "=== [5/6] 脚手架项目特有脚本检查 ==="

SCRIPT_DIRS=(
    "scripts/hooks"
    "scripts/gates"
    "scripts/redlines"
    "scripts/preflight"
    "scripts/checkpoint"
)

for dir in "${SCRIPT_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        SCRIPT_COUNT=$(find "$dir" -name "*.sh" -type f | wc -l)
        echo "✅ 目录存在: $dir ($SCRIPT_COUNT 个脚本)"
    else
        echo "⚠️ 目录不存在: $dir (建议创建)"
        WARNINGS=$((WARNINGS + 1))
    fi
done

echo ""

# ─────────────────────────────────────────────────────────────
# 第六部分：总结报告
# ─────────────────────────────────────────────────────────────

echo "╔══════════════════════════════════════════════════════════╗"
echo "║            验证结果汇总                                  ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  错误数: $ERRORS                                           ║"
echo "║  警告数: $WARNINGS                                         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

if [[ "$ERRORS" -gt 0 ]]; then
    echo "❌ 配置验证失败，请修复上述错误"
    exit 1
fi

echo "✅ 配置验证通过"
echo ""
echo "=== Hook 配置清单（脚手架项目） ==="
echo ""
echo "SessionStart:"
echo "  └─ session-start-reminder.sh  (P1: 会话开始提醒)"
echo ""
echo "PreToolUse:"
echo "  ├─ gate-skill-scan.sh         (G1: 技能扫描门控)"
echo "  ├─ gate-execute-phase.sh      (G2: 执行阶段门控)"
echo "  ├─ gate-lazy-pre.sh           (G3: 懒惰模式阻断)"
echo "  ├─ 文件大小限制               (>800行阻断)"
echo "  ├─ 敏感文件保护               (.env/password等阻断)"
echo "  ├─ check-dangerous-file.sh    (危险文件拦截)"
echo "  ├─ check-tdd.sh               (TDD合规提醒)"
echo "  └─ check-context.sh           (外部调用检查)"
echo ""
echo "PostToolUse:"
echo "  ├─ detect-lazy-post.sh        (G4: 懒惰模式检测)"
echo "  ├─ detect-context-pollution.sh (G5: 上下文污染检测)"
echo "  ├─ Go格式化                   (gofmt -w)"
echo "  └─ Markdown格式化             (prettier --write)"
echo ""
echo "Stop:"
echo "  ├─ session-end-gate.sh        (G6: 验证门控 + 污染检查)"
echo "  └─ scripts/gates/all.sh       (项目门控汇总)"
echo ""
echo "=== 状态文件结构 ==="
echo ".claude/session/"
echo "  ├─ .flow-state          (工作流状态)"
echo "  ├─ .flow-state.example  (状态模板)"
echo "  ├─ .skill-scanned       (技能扫描标记)"
echo "  ├─ .verified            (验证完成标记)"
echo "  ├─ .lazy-detected       (懒惰模式标记)"
echo "  ├─ .pollution-detected  (上下文污染标记)"
echo "  ├─ .tool-history        (工具调用历史)"
echo "  └─ .fail-count          (失败计数)"
echo ""
echo "=== 脚手架项目特有目录 ==="
echo "scripts/"
echo "  ├─ hooks/               (项目特定Hook)"
echo "  ├─ gates/               (质量门控脚本G1-G7)"
echo "  ├─ redlines/            (红线检查R1-R3)"
echo "  ├─ preflight/           (环境预检)"
echo "  ├─ checkpoint/          (状态保存/恢复)"
echo "  └─ tests/               (脚手架自测)"
echo ""
echo ".agent/"
echo "  └─ state/               (项目状态管理)"
echo ""
echo "=== 下一步操作 ==="
echo "1. 运行项目门控: make gate"
echo "2. 启动新会话测试门控效果"
echo "3. 根据警告信息完善配置"
echo ""

exit 0
#!/bin/bash
# scripts/gates/G4-verify.sh
# 验证Lint通过

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LINT_OUTPUT="$PROJECT_ROOT/.agent/logs/lint.json"

echo "[G4] Lint验证..."

# 检查lint输出文件
if [ ! -f "$LINT_OUTPUT" ]; then
    echo "[G4] ⚠️ 缺少lint输出，运行: make lint"
    # 尝试运行
    cd "$PROJECT_ROOT"
    if command -v golangci-lint &>/dev/null; then
        golangci-lint run --out-format=json > "$LINT_OUTPUT" 2>&1 || true
    else
        echo "[G4] ❌ golangci-lint 未安装"
        exit 1
    fi
fi

# 解析lint结果
if command -v jq &>/dev/null; then
    ISSUES=$(jq '.Issues | length' "$LINT_OUTPUT" 2>/dev/null || echo "0")
    if [ "$ISSUES" -eq 0 ]; then
        echo "[G4] ✅ Lint通过 (无问题)"
        exit 0
    else
        echo "[G4] ❌ 发现 $ISSUES 个问题"
        jq -r '.Issues[] | "\(.Pos.Filename):\(.Pos.Line): \(.Text)"' "$LINT_OUTPUT" | head -10
        exit 1
    fi
else
    # 无jq时的简单检查
    if grep -q '"Issues":\[\]' "$LINT_OUTPUT" || grep -q '"Issues": null' "$LINT_OUTPUT"; then
        echo "[G4] ✅ Lint通过"
        exit 0
    else
        echo "[G4] ❌ Lint发现问题"
        exit 1
    fi
fi

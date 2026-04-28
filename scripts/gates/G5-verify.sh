#!/bin/bash
# scripts/gates/G5-verify.sh
# 验证测试通过

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_OUTPUT="$PROJECT_ROOT/.agent/logs/test.json"

echo "[G5] 测试验证..."

# 检查测试输出
if [ ! -f "$TEST_OUTPUT" ]; then
    echo "[G5] ⚠️ 缺少测试输出，运行: make test"
    cd "$PROJECT_ROOT"
    go test ./... -race -json > "$TEST_OUTPUT" 2>&1 || true
fi

# 解析测试结果
if command -v jq &>/dev/null; then
    # 统计测试结果
    TOTAL=$(jq -r 'select(.Action=="pass" or .Action=="fail") | .Action' "$TEST_OUTPUT" 2>/dev/null | wc -l)
    PASSES=$(jq -r 'select(.Action=="pass") | .Action' "$TEST_OUTPUT" 2>/dev/null | wc -l)
    FAILS=$(jq -r 'select(.Action=="fail") | .Action' "$TEST_OUTPUT" 2>/dev/null | wc -l)

    if [ "$FAILS" -eq 0 ] && [ "$PASSES" -gt 0 ]; then
        echo "[G5] ✅ 测试通过 ($PASSES/$TOTAL)"
        exit 0
    else
        echo "[G5] ❌ 测试失败 ($FAILS/$TOTAL)"
        jq -r 'select(.Action=="fail") | "\(.Package) \(.Test): \(.Output)"' "$TEST_OUTPUT" | head -20
        exit 1
    fi
else
    # 简单检查
    if grep -q '"Action":"fail"' "$TEST_OUTPUT"; then
        echo "[G5] ❌ 有测试失败"
        exit 1
    elif grep -q '"Action":"pass"' "$TEST_OUTPUT"; then
        echo "[G5] ✅ 测试通过"
        exit 0
    else
        echo "[G5] ⚠️ 未检测到测试结果"
        exit 1
    fi
fi

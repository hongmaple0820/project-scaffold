#!/bin/bash
# scripts/gates/G6-verify.sh
# 验证覆盖率

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COVERAGE_FILE="$PROJECT_ROOT/.agent/logs/coverage.out"

echo "[G6] 覆盖率验证..."

# 生成覆盖率报告
if [ ! -f "$COVERAGE_FILE" ]; then
    echo "[G6] ⚠️ 缺少覆盖率报告，运行: make coverage"
    cd "$PROJECT_ROOT"
    go test -coverprofile="$COVERAGE_FILE" ./... || true
fi

# 解析覆盖率
if [ -f "$COVERAGE_FILE" ]; then
    # Go覆盖率格式: coverage: 80.5% of statements
    COVERAGE=$(go tool cover -func="$COVERAGE_FILE" | tail -1 | awk '{print $3}' | sed 's/%//')

    if [ -n "$COVERAGE" ]; then
        echo "[G6] 覆盖率: ${COVERAGE}%"

        # 比较（bash浮点比较）
        if awk "BEGIN {exit !($COVERAGE >= 80.0)}"; then
            echo "[G6] ✅ 覆盖率达标 (≥80%)"
            exit 0
        else
            echo "[G6] ❌ 覆盖率不足 (<80%)"
            exit 1
        fi
    else
        echo "[G6] ⚠️ 无法解析覆盖率"
        exit 1
    fi
else
    echo "[G6] ❌ 无法生成覆盖率报告"
    exit 1
fi

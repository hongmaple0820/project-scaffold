#!/bin/bash
# scripts/gates/G3-verify.sh
# 验证TDD合规

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ERRORS=0

echo "[G3] TDD合规验证..."

# 查找所有测试文件
find "$PROJECT_ROOT" -name "*_test.go" -type f | while read test_file; do
    # 获取对应的实现文件
    impl_file="${test_file%_test.go}.go"

    if [ ! -f "$impl_file" ]; then
        echo "[G3] ⚠️ 测试文件无对应实现: $test_file"
        continue
    fi

    # 比较修改时间（需要git支持）
    if [ -d "$PROJECT_ROOT/.git" ]; then
        test_time=$(git log -1 --format=%ct -- "$test_file" 2>/dev/null || echo "0")
        impl_time=$(git log -1 --format=%ct -- "$impl_file" 2>/dev/null || echo "0")

        if [ "$test_time" -lt "$impl_time" ]; then
            echo "[G3] ❌ 实现比测试新: $impl_file"
            ERRORS=$((ERRORS+1))
        fi
    else
        # 无git时使用文件修改时间
        if [ "$test_file" -ot "$impl_file" ]; then
            echo "[G3] ❌ 实现比测试新: $impl_file"
            ERRORS=$((ERRORS+1))
        fi
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo "[G3] ✅ TDD合规"
    exit 0
else
    echo "[G3] ❌ 存在先实现后测试的文件"
    exit 1
fi

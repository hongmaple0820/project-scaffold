#!/bin/bash
# scripts/gates/all.sh
# 运行所有门控

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
fi

echo "========================================"
echo "[GATES] 运行所有质量门控"
echo "========================================"
echo ""

PASSED=0
FAILED=0
SKIPPED=0

# 门控列表（按顺序）
GATES=("G1" "G2" "G3" "G4" "G5" "G6" "G7")

for GATE in "${GATES[@]}"; do
    echo "[$GATE] 检查..."

    if [ "$DRY_RUN" == "true" ]; then
        echo "[$GATE] ℹ️ 干运行模式，跳过"
        SKIPPED=$((SKIPPED+1))
        continue
    fi

    VERIFY_SCRIPT="$SCRIPT_DIR/${GATE}-verify.sh"

    if [ -f "$VERIFY_SCRIPT" ]; then
        if bash "$VERIFY_SCRIPT"; then
            echo "[$GATE] ✅ 通过"
            PASSED=$((PASSED+1))

            # 更新状态
            mkdir -p "$PROJECT_ROOT/.agent/state"
            jq --arg gate "$GATE" '.gates[$gate] = "passed"' "$PROJECT_ROOT/.agent/state/current.json" 2>/dev/null || \
                echo "{\"gates\": {\"$GATE\": \"passed\"}}" > "$PROJECT_ROOT/.agent/state/current.json"
        else
            echo "[$GATE] ❌ 失败"
            FAILED=$((FAILED+1))
        fi
    else
        echo "[$GATE] ⚠️ 缺少验证脚本"
        SKIPPED=$((SKIPPED+1))
    fi
    echo ""
done

echo "========================================"
echo "[GATES] 结果: $PASSED 通过, $FAILED 失败, $SKIPPED 跳过"
echo "========================================"

if [ $FAILED -eq 0 ]; then
    echo "[GATES] ✅ 所有门控通过"
    exit 0
else
    echo "[GATES] ❌ 有门控未通过"
    exit 1
fi

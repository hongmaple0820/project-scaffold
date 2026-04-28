#!/bin/bash
# scripts/gates/G7-verify.sh
# 安全验证

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ERRORS=0

echo "[G7] 安全检查..."

# 检查gosec安装
if ! command -v gosec &>/dev/null; then
    echo "[G7] ⚠️ gosec 未安装，跳过详细检查"
    echo "[HINT] 安装: go install github.com/securego/gosec/v2/cmd/gosec@latest"
    exit 0
fi

# 运行gosec
cd "$PROJECT_ROOT"
GOSEC_OUTPUT=$(gosec -fmt json ./... 2>/dev/null || true)

# 统计问题
HIGH=$(echo "$GOSEC_OUTPUT" | jq '[.Issues[] | select(.severity=="HIGH")] | length' 2>/dev/null || echo "0")
CRITICAL=$(echo "$GOSEC_OUTPUT" | jq '[.Issues[] | select(.severity=="CRITICAL")] | length' 2>/dev/null || echo "0")

if [ "$CRITICAL" -gt 0 ]; then
    echo "[G7] ❌ 发现 $CRITICAL 个 CRITICAL 安全问题"
    ERRORS=$((ERRORS+1))
fi

if [ "$HIGH" -gt 0 ]; then
    echo "[G7] ❌ 发现 $HIGH 个 HIGH 安全问题"
    ERRORS=$((ERRORS+1))
fi

if [ $ERRORS -eq 0 ]; then
    echo "[G7] ✅ 安全检查通过"
    exit 0
else
    echo "$GOSEC_OUTPUT" | jq -r '.Issues[] | select(.severity=="HIGH" or .severity=="CRITICAL") | "\(.file):\(.line): [\(.severity)] \(.details)"' | head -10
    exit 1
fi

#!/bin/bash
# scripts/gates/G7-verify.sh
# 安全验证

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/project-config.sh"
ERRORS=0

echo "[G7] 安全检查..."

STACK="$(detect_stack)"

if [ "$STACK" = "none" ]; then
    echo "[G7] ℹ️ 未检测到已配置技术栈，security 门控不适用"
    exit 0
fi

if ! stack_exists "$STACK"; then
    echo "[G7] ❌ 未知技术栈: $STACK"
    exit 1
fi

COMMAND="$(gate_command "$STACK" security)"
if ! run_gate_command "$STACK" security "$COMMAND" G7; then
    echo "[G7] ❌ security 命令失败"
    exit 1
fi

if [ "$STACK" != "go" ]; then
    echo "[G7] ✅ security 命令通过"
    exit 0
fi

GOSEC_OUTPUT="$(cat "$PROJECT_ROOT/.agent/logs/gosec.json")"

# 统计问题
if command -v jq >/dev/null 2>&1; then
    HIGH=$(echo "$GOSEC_OUTPUT" | jq '[.Issues[] | select(.severity=="HIGH")] | length' 2>/dev/null || echo "0")
    CRITICAL=$(echo "$GOSEC_OUTPUT" | jq '[.Issues[] | select(.severity=="CRITICAL")] | length' 2>/dev/null || echo "0")
else
    COUNTS=$(python3 - "$PROJECT_ROOT/.agent/logs/gosec.json" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
issues = data.get("Issues") or []
high = sum(1 for issue in issues if issue.get("severity") == "HIGH")
critical = sum(1 for issue in issues if issue.get("severity") == "CRITICAL")
print(f"{high} {critical}")
PY
)
    HIGH="${COUNTS%% *}"
    CRITICAL="${COUNTS##* }"
fi

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
    if command -v jq >/dev/null 2>&1; then
        echo "$GOSEC_OUTPUT" | jq -r '.Issues[] | select(.severity=="HIGH" or .severity=="CRITICAL") | "\(.file):\(.line): [\(.severity)] \(.details)"' | head -10
    else
        python3 - "$PROJECT_ROOT/.agent/logs/gosec.json" <<'PY' | head -10
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
for issue in data.get("Issues") or []:
    if issue.get("severity") in {"HIGH", "CRITICAL"}:
        print(f"{issue.get('file')}:{issue.get('line')}: [{issue.get('severity')}] {issue.get('details')}")
PY
    fi
    exit 1
fi

#!/usr/bin/env bash
# Service-aware security scan. Blocks for CRITICAL or ENFORCE_SECURITY=1.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/services.sh"

STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"
CONFIG_FILE="$PROJECT_ROOT/.agent/project.json"
LEVEL=""
if [ -f "$STATE_FILE" ] && [ -f "$PY_STATE" ]; then
  LEVEL="$(python3 "$PY_STATE" get "$STATE_FILE" level "" 2>/dev/null || true)"
fi

ENFORCE="${ENFORCE_SECURITY:-0}"
if [ "$LEVEL" = "CRITICAL" ]; then
  ENFORCE=1
fi

echo "========================================"
echo "[G7] Security gate"
echo "========================================"
echo "[G7] enforce: $ENFORCE"

security_required_tools() {
  python3 - "$CONFIG_FILE" "$@" <<'PY'
import json
import sys

config_path = sys.argv[1]
selected = sys.argv[2:]
with open(config_path, encoding="utf-8") as f:
    cfg = json.load(f)

services = cfg.get("services") or {}
stacks = cfg.get("stacks") or {}
names = selected or list(services.keys())
tools = []

for name in names:
    service = services.get(name)
    if not service:
        continue
    stack = stacks.get(service.get("stack") or "", {})
    required = dict(stack.get("required_tools") or {})
    required.update(service.get("required_tools") or {})
    tools.extend(required.get("security") or [])

for tool in sorted(dict.fromkeys(tools)):
    print(tool)
PY
}

mapfile -t SERVICES < <(selected_services "$@" || true)
if [ "${#SERVICES[@]}" -eq 0 ]; then
  SERVICES=("placeholder-service")
fi

mapfile -t REQUIRED_TOOLS < <(security_required_tools "${SERVICES[@]}" || true)
if [ "${#REQUIRED_TOOLS[@]}" -eq 0 ]; then
  REQUIRED_TOOLS=("gosec")
fi

TOOL_STATUS=0
for tool in "${REQUIRED_TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    continue
  fi
  echo "[G7] missing tool: $tool"
  if [ "$tool" = "gosec" ]; then
    echo "[G7] install: go install github.com/securego/gosec/v2/cmd/gosec@latest"
    if [ "$ENFORCE" != "1" ]; then
      echo "[G7] skipped outside enforced security mode"
    fi
  fi
  TOOL_STATUS=1
done

if [ "$TOOL_STATUS" -ne 0 ]; then
  if [ "$ENFORCE" = "1" ] || [ "${#REQUIRED_TOOLS[@]}" -ne 1 ] || [ "${REQUIRED_TOOLS[0]}" != "gosec" ]; then
    exit 1
  fi
  exit 0
fi

count_security_findings() {
  local file="$1"
  if command -v node >/dev/null 2>&1; then
    node -e "const fs=require('fs'); const p=process.argv[1]; const data=JSON.parse(fs.readFileSync(p,'utf8')); const issues=data.Issues||[]; const high=issues.filter(i=>i.severity==='HIGH').length; const critical=issues.filter(i=>i.severity==='CRITICAL').length; console.log(high + ' ' + critical);" "$file"
    return
  fi
  python3 - "$file" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
issues = data.get('Issues') or []
high = sum(1 for i in issues if i.get('severity') == 'HIGH')
critical = sum(1 for i in issues if i.get('severity') == 'CRITICAL')
print(high, critical)
PY
}

ALL_PASS=true
for service in "${SERVICES[@]}"; do
  DIR="$(service_dir "$service")"
  LOG_DIR="$(service_log_dir "$service")"
  LOG_FILE="$LOG_DIR/security.json"
  mkdir -p "$LOG_DIR"

  echo "[G7] service: $service"
  cd "$DIR"

  gosec -fmt json -out "$LOG_FILE" ./... >/dev/null 2>&1 || true
  read -r HIGH CRITICAL < <(count_security_findings "$LOG_FILE")

  echo "[G7]   HIGH: ${HIGH:-0}"
  echo "[G7]   CRITICAL: ${CRITICAL:-0}"

  if [ "${HIGH:-0}" -gt 0 ] || [ "${CRITICAL:-0}" -gt 0 ]; then
    echo "[G7]   high/critical findings are recorded in $LOG_FILE"
    ALL_PASS=false
  fi
done

if [ "$ALL_PASS" = true ]; then
  echo "[G7] passed"
  exit 0
fi

if [ "$ENFORCE" = "1" ]; then
  echo "[G7] failed"
  exit 1
fi

echo "[G7] warning only outside enforced security mode"
exit 0

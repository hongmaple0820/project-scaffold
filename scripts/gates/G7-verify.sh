#!/usr/bin/env bash
# Service-aware security scan. Blocks for CRITICAL or ENFORCE_SECURITY=1.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/services.sh"

STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"
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

if ! command -v gosec >/dev/null 2>&1; then
  echo "[G7] gosec missing"
  echo "[G7] install: go install github.com/securego/gosec/v2/cmd/gosec@latest"
  if [ "$ENFORCE" = "1" ]; then
    exit 1
  fi
  echo "[G7] skipped outside enforced security mode"
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
for service in $(selected_services "$@"); do
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

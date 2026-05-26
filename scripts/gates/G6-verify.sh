#!/usr/bin/env bash
# Service-aware Go coverage reporting. Blocks only when ENFORCE_COVERAGE=1 or CRITICAL.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/services.sh"

GO_CMD="$(go_cmd)"
if [ -z "$GO_CMD" ]; then
  echo "[G6] Go command is not executable in this shell"
  echo "[G6] On Windows, use: powershell -ExecutionPolicy Bypass -File scripts\\workflow\\verify.ps1 -Service <service>"
  echo "[G6] In WSL, install a Linux Go toolchain instead of relying on Windows go.exe"
  exit 1
fi

STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"
LEVEL=""
if [ -f "$STATE_FILE" ] && [ -f "$PY_STATE" ]; then
  LEVEL="$(python3 "$PY_STATE" get "$STATE_FILE" level "" 2>/dev/null || true)"
fi

THRESHOLD="${COVERAGE_THRESHOLD:-0}"
ENFORCE="${ENFORCE_COVERAGE:-0}"
if [ "$LEVEL" = "CRITICAL" ]; then
  ENFORCE=1
  if [ "$THRESHOLD" = "0" ]; then THRESHOLD=80; fi
fi

echo "========================================"
echo "[G6] Coverage gate"
echo "========================================"
echo "[G6] threshold: ${THRESHOLD}%"
echo "[G6] enforce: $ENFORCE"

TMP="$PROJECT_ROOT/.agent/logs/coverage-values.tmp"
mkdir -p "$PROJECT_ROOT/.agent/logs"
: > "$TMP"

ALL_PASS=true
for service in $(selected_services "$@"); do
  DIR="$(service_dir "$service")"
  LOG_DIR="$(service_log_dir "$service")"
  mkdir -p "$LOG_DIR"

  echo "[G6] service: $service"
  cd "$DIR"

  COVERAGE_FILE="$LOG_DIR/coverage.out"
  COVERAGE_LOG="$LOG_DIR/coverage.txt"
  if "$GO_CMD" test -coverprofile="$COVERAGE_FILE" ./... > "$COVERAGE_LOG" 2>&1; then
    COVERAGE="$("$GO_CMD" tool cover -func="$COVERAGE_FILE" 2>/dev/null | awk '/total:/ {gsub("%","",$3); print $3}' || true)"
    COVERAGE="${COVERAGE:-0}"
    echo "[G6]   coverage: ${COVERAGE}%"
    echo "$COVERAGE" >> "$TMP"
  else
    echo "[G6]   coverage command failed"
    head -40 "$COVERAGE_LOG" || true
    ALL_PASS=false
  fi
done

AVG_COVERAGE="$(awk '{sum+=$1; count++} END {if (count == 0) print "0.0"; else printf "%.1f", sum/count}' "$TMP")"
rm -f "$TMP"

echo "[G6] average coverage: ${AVG_COVERAGE}%"

if [ "$ALL_PASS" != true ]; then
  echo "[G6] failed"
  exit 1
fi

if awk -v cov="$AVG_COVERAGE" -v threshold="$THRESHOLD" 'BEGIN { exit !(cov + 0 >= threshold + 0) }'; then
  echo "[G6] passed"
  exit 0
fi

if [ "$ENFORCE" = "1" ]; then
  echo "[G6] failed: coverage below threshold"
  exit 1
fi

echo "[G6] warning only: coverage below threshold"
exit 0

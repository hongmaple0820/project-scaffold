#!/usr/bin/env bash
# Service-aware test verification.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/services.sh"

GO_CMD="$(go_cmd)"
if [ -z "$GO_CMD" ]; then
  echo "[G5] Go command is not executable in this shell"
  echo "[G5] On Windows, use: powershell -ExecutionPolicy Bypass -File scripts\\workflow\\verify.ps1 -Service <service>"
  echo "[G5] In WSL, install a Linux Go toolchain instead of relying on Windows go.exe"
  exit 1
fi

echo "========================================"
echo "[G5] Test gate"
echo "========================================"

ALL_PASS=true
for service in $(selected_services "$@"); do
  DIR="$(service_dir "$service")"
  LOG_DIR="$(service_log_dir "$service")"
  mkdir -p "$LOG_DIR"

  echo "[G5] service: $service"
  cd "$DIR"

  if "$GO_CMD" test ./... -race -json > "$LOG_DIR/test.json" 2>&1; then
    echo "[G5]   race tests passed"
    continue
  fi

  if grep -q -- "-race requires cgo" "$LOG_DIR/test.json"; then
    echo "[G5]   race unavailable; retrying without -race"
    if "$GO_CMD" test ./... -json > "$LOG_DIR/test.no-race.json" 2>&1; then
      echo "[G5]   non-race tests passed"
      continue
    fi
    echo "[G5]   non-race tests failed"
    grep '"Action":"fail"' "$LOG_DIR/test.no-race.json" | head -10 || true
    ALL_PASS=false
    continue
  fi

  echo "[G5]   tests failed"
  grep '"Action":"fail"' "$LOG_DIR/test.json" | head -10 || true
  ALL_PASS=false
done

if [ "$ALL_PASS" = true ]; then
  echo "[G5] passed"
  exit 0
fi

echo "[G5] failed"
exit 1

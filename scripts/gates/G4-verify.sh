#!/usr/bin/env bash
# Service-aware lint verification.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/services.sh"

GO_CMD="$(go_cmd)"
if [ -z "$GO_CMD" ]; then
  echo "[G4] Go command is not executable in this shell"
  echo "[G4] On Windows, use: powershell -ExecutionPolicy Bypass -File scripts\\workflow\\verify.ps1 -Service <service>"
  echo "[G4] In WSL, install a Linux Go toolchain instead of relying on Windows go.exe"
  exit 1
fi

echo "========================================"
echo "[G4] Lint gate"
echo "========================================"

ALL_PASS=true
for service in $(selected_services "$@"); do
  DIR="$(service_dir "$service")"
  LOG_DIR="$(service_log_dir "$service")"
  mkdir -p "$LOG_DIR"

  echo "[G4] service: $service"
  cd "$DIR"

  if command -v golangci-lint >/dev/null 2>&1; then
    if golangci-lint run --out-format=json > "$LOG_DIR/lint.json" 2>&1; then
      echo "[G4]   golangci-lint passed"
    else
      echo "[G4]   golangci-lint failed"
      head -40 "$LOG_DIR/lint.json" || true
      ALL_PASS=false
    fi
  else
    echo "[G4]   golangci-lint missing; fallback to go vet"
    if "$GO_CMD" vet ./... > "$LOG_DIR/vet.txt" 2>&1; then
      echo "[G4]   go vet passed"
    else
      echo "[G4]   go vet failed"
      head -40 "$LOG_DIR/vet.txt" || true
      ALL_PASS=false
    fi
  fi
done

if [ "$ALL_PASS" = true ]; then
  echo "[G4] passed"
  exit 0
fi

echo "[G4] failed"
exit 1

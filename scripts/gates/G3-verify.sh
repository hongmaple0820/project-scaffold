#!/usr/bin/env bash
# TDD evidence gate. Day-to-day M work warns; L/CRITICAL and ENFORCE_TDD=1 block.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"

echo "========================================"
echo "[G3] TDD evidence gate"
echo "========================================"

LEVEL=""
if [ -f "$STATE_FILE" ] && [ -f "$PY_STATE" ]; then
  LEVEL="$(python3 "$PY_STATE" get "$STATE_FILE" level "" 2>/dev/null || true)"
fi

ENFORCE="${ENFORCE_TDD:-0}"
case "$LEVEL" in
  L|CRITICAL) ENFORCE=1 ;;
esac

if ! git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  echo "[G3] not a Git repository; cannot inspect changed files"
  [ "$ENFORCE" = "1" ] && exit 1 || exit 0
fi

collect_changed_go_files() {
  local tracked untracked

  tracked="$(
    git -C "$PROJECT_ROOT" diff --name-only --diff-filter=ACMR HEAD -- '*.go' 2>/dev/null || true
    git -C "$PROJECT_ROOT" diff --cached --name-only --diff-filter=ACMR -- '*.go' 2>/dev/null || true
  )"
  untracked="$(git -C "$PROJECT_ROOT" ls-files --others --exclude-standard -- '*.go' 2>/dev/null || true)"

  printf '%s\n%s\n' "$tracked" "$untracked" \
    | sed '/^$/d' \
    | grep -vE '(_test\.go$|/vendor/|/generated/)' \
    | sort -u
}

mapfile -t CHANGED_GO < <(collect_changed_go_files || true)

if [ "${#CHANGED_GO[@]}" -eq 0 ]; then
  echo "[G3] no changed Go implementation files"
  exit 0
fi

MISSING=0
for file in "${CHANGED_GO[@]}"; do
  test_file="${file%.go}_test.go"
  if [ ! -f "$PROJECT_ROOT/$test_file" ]; then
    echo "[G3] missing paired test: $file -> $test_file"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$MISSING" -eq 0 ]; then
  echo "[G3] paired tests found for changed Go files"
  exit 0
fi

if [ "$ENFORCE" = "1" ]; then
  echo "[G3] failed: $MISSING changed implementation file(s) lack paired tests"
  echo "[G3] add tests or document why TDD is not applicable in the task verification artifact"
  exit 1
fi

echo "[G3] warning only: $MISSING changed implementation file(s) lack paired tests"
echo "[G3] set ENFORCE_TDD=1, or use L/CRITICAL task level, to block"
exit 0

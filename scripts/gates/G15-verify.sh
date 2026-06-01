#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[G15] Context pollution gate"

STAGED=$(cd "$ROOT" && git diff --cached --name-only 2>/dev/null || true)
for pattern in ".claude/worktrees/" ".agent/" ".planning/" ".scale/cache/"; do
  if echo "$STAGED" | grep -q "^$pattern"; then
    echo "[G15] staged files under $pattern"
    exit 1
  fi
done

echo "[G15] passed"

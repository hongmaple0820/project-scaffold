#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

echo "========================================"
echo "[VALIDATE] configuration"
echo "========================================"
echo ""

echo "[CHECK] required files..."
REQUIRED_FILES=(
  "AGENTS.md"
  "CLAUDE.md"
  "README.md"
  "Makefile"
  ".scale/workspace.json"
  ".scale/governance.lock.json"
  ".agent/project.json"
  ".claude/settings.json"
  ".claude/workflow.json"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$PROJECT_ROOT/$file" ]; then
    echo "[OK] $file"
  else
    echo "[ERROR] missing: $file"
    ERRORS=$((ERRORS+1))
  fi
done
echo ""

echo "[CHECK] executable scripts..."
REQUIRED_SCRIPTS=(
  "scripts/preflight/all.sh"
  "scripts/gates/all.sh"
  "scripts/checkpoint/save.sh"
  "scripts/workflow/verify.sh"
  "scripts/workflow/lint-scaffold.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
  if [ -f "$PROJECT_ROOT/$script" ]; then
    chmod +x "$PROJECT_ROOT/$script" 2>/dev/null || true
    echo "[OK] $script"
  else
    echo "[ERROR] missing: $script"
    ERRORS=$((ERRORS+1))
  fi
done
echo ""

echo "[CHECK] JSON files..."
if command -v python3 >/dev/null 2>&1; then
  python3 - "$PROJECT_ROOT" <<'PY' || ERRORS=$((ERRORS+1))
from __future__ import annotations
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
paths = [
    root / ".scale" / "workspace.json",
    root / ".scale" / "governance.lock.json",
    root / ".agent" / "project.json",
    root / ".claude" / "settings.json",
    root / ".claude" / "workflow.json",
]

failed = False
for path in paths:
    try:
        with path.open(encoding="utf-8") as f:
            json.load(f)
        print(f"[OK] {path.relative_to(root)}")
    except Exception as exc:
        failed = True
        print(f"[ERROR] invalid JSON: {path.relative_to(root)} :: {exc}")

raise SystemExit(1 if failed else 0)
PY
else
  echo "[ERROR] python3 not available for JSON validation"
  ERRORS=$((ERRORS+1))
fi
echo ""

echo "[CHECK] shell LF endings..."
CRLF_FILES=$(python3 - "$PROJECT_ROOT" <<'PY'
from __future__ import annotations
import sys
from pathlib import Path

root = Path(sys.argv[1])
for base in [root / "scripts", root / ".claude" / "hooks"]:
    if not base.exists():
        continue
    for path in base.rglob("*.sh"):
        try:
            data = path.read_bytes()
        except OSError:
            continue
        if b"\r\n" in data:
            print(path.relative_to(root))
PY
)

if [ -n "$CRLF_FILES" ]; then
  echo "[ERROR] shell scripts contain CRLF:"
  echo "$CRLF_FILES"
  ERRORS=$((ERRORS+1))
else
  echo "[OK] shell scripts use LF"
fi
echo ""

echo "========================================"
if [ "$ERRORS" -eq 0 ]; then
  echo "[VALIDATE] OK"
  exit 0
else
  echo "[VALIDATE] FAIL: $ERRORS issue(s)"
  exit 1
fi

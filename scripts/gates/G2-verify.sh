#!/bin/bash
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"
ARTIFACTS=$(python3 "$PY_STATE" get "$STATE_FILE" artifacts_dir "" 2>/dev/null || true)
if [ -z "$ARTIFACTS" ]; then
  echo "artifacts_dir missing in .agent/state/current.json"
  exit 1
fi
PLAN="$PROJECT_ROOT/$ARTIFACTS/plan.md"
if [ ! -f "$PLAN" ]; then echo "missing plan artifact: $PLAN"; exit 1; fi
python3 - "$PLAN" <<'PY'
from __future__ import annotations
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

required = [
    ("scope", r"^##\s+.*(Scope|范围)", "plan missing scope"),
    ("boundary", r"^##\s+.*(Boundary|边界)", "plan missing boundary"),
    ("acceptance", r"^##\s+.*(Acceptance|验收)", "plan missing acceptance criteria"),
    ("risks", r"^##\s+.*(Risks?|风险)", "plan missing risks"),
    ("rollback", r"^##\s+.*(Rollback|回滚)", "plan missing rollback"),
    ("verification", r"^##\s+.*(Verification|验证)", "plan missing verification"),
]

placeholders = {
    "待填写",
    "待填写。",
    "todo",
    "tbd",
    "n/a",
    "na",
    "none",
    "暂无",
}


def section_lines(pattern: str) -> list[str] | None:
    match = re.search(pattern, text, flags=re.IGNORECASE | re.MULTILINE)
    if not match:
        return None
    start = match.end()
    next_heading = re.search(r"^##\s+", text[start:], flags=re.MULTILINE)
    end = start + next_heading.start() if next_heading else len(text)
    raw_lines = text[start:end].splitlines()
    lines = []
    for line in raw_lines:
        cleaned = line.strip().strip("-*` \t").strip()
        if not cleaned:
            continue
        if cleaned.lower() in placeholders:
            continue
        lines.append(cleaned)
    return lines


errors = []
for name, pattern, missing_message in required:
    lines = section_lines(pattern)
    if lines is None:
        errors.append(missing_message)
    elif not lines:
        errors.append(f"plan {name} section has no meaningful content")

if errors:
    for error in errors:
        print(error)
    raise SystemExit(1)
PY
echo "[G2] passed"

#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "${NAME:-}" ]; then
    echo "[ERROR] set NAME, for example: NAME=my-feature bash scripts/init-plan.sh"
    exit 1
fi

LEVEL="${LEVEL:-M}"
echo "[INIT] scripts/init-plan.sh is a compatibility wrapper; use scripts/workflow/new-task.sh directly."
bash "$PROJECT_ROOT/scripts/workflow/new-task.sh" "$NAME" "$LEVEL"

#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bash "$ROOT/scripts/workflow/verify.sh" --profile scaffold
echo "[G5] scaffold self-check completed"

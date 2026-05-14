#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MODE="all"
DRY_RUN=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --workflow) MODE="workflow" ;;
    --quality) MODE="quality" ;;
    --all) MODE="all" ;;
  esac
  shift
done
case "$MODE" in
  workflow) GATES=(G1 G2) ;;
  quality) GATES=(G3 G4 G5 G6 G7) ;;
  *) GATES=(G1 G2 G3 G4 G5 G6 G7) ;;
esac
FAILED=0
for gate in "${GATES[@]}"; do
  script="$SCRIPT_DIR/$gate-verify.sh"
  echo "[GATE] $gate"
  if [ ! -f "$script" ]; then echo "missing $script"; FAILED=$((FAILED+1)); continue; fi
  if [ "$DRY_RUN" = true ]; then echo "  exists"; continue; fi
  if ! bash "$script"; then FAILED=$((FAILED+1)); fi
done
if [ "$FAILED" -gt 0 ]; then echo "[GATE] failed: $FAILED"; exit 1; fi
echo "[GATE] passed"

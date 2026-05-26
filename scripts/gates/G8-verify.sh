#!/usr/bin/env bash
# G8: Document standards verification.
# Checks new/modified markdown files against DOCUMENT_STANDARDS.md.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "========================================"
echo "[G8] Document standards gate"
echo "========================================"

DOC_STANDARD="$PROJECT_ROOT/docs/standards/common/DOCUMENT_STANDARDS.md"

if [ ! -f "$DOC_STANDARD" ]; then
  echo "[G8] skipped: DOCUMENT_STANDARDS.md not found"
  exit 0
fi

# Find new/modified markdown files in the last commit
CHANGED_MD=$(git -C "$PROJECT_ROOT" diff --name-only --diff-filter=AM HEAD~1 2>/dev/null | grep -E '\.md$' || true)

if [ -z "$CHANGED_MD" ]; then
  echo "[G8] passed: no new/modified markdown files"
  exit 0
fi

echo "[G8] checking changed files:"
echo "$CHANGED_MD"
echo ""

ALL_PASS=true

for file in $CHANGED_MD; do
  filepath="$PROJECT_ROOT/$file"

  if [ ! -f "$filepath" ]; then
    continue
  fi

  echo "[G8] checking: $file"

  # Check 1: Version header (for standards/docs)
  if [[ "$file" == docs/standards/* ]] || [[ "$file" == docs/standards/projects/* ]]; then
    if ! head -20 "$filepath" | grep -q '^\*\*版本\*\*'; then
      echo "  [WARN] missing version header"
    fi
  fi

  # Check 2: File location (should be in proper directory)
  if [[ "$file" == docs/e2e* ]]; then
    echo "  [WARN] e2e docs should be in tests/e2e/"
    ALL_PASS=false
  fi

  # Check 3: No hardcoded secrets
  if grep -qiE '(password|secret|token|api_key)\s*[:=]\s*["\x27][^"\x27]{8,}' "$filepath" 2>/dev/null; then
    echo "  [FAIL] possible hardcoded secret detected"
    ALL_PASS=false
  fi

  # Check 4: Internal links should use relative paths
  if grep -qE '\[.*\]\(http(s)?://localhost' "$filepath" 2>/dev/null; then
    echo "  [WARN] localhost links found, consider relative paths"
  fi

done

echo ""
if [ "$ALL_PASS" = true ]; then
  echo "[G8] passed"
  exit 0
fi

echo "[G8] failed"
exit 1

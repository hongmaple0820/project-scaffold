#!/usr/bin/env bash
# Verify unified product version metadata.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

find_python() {
  for candidate in python3 python py; do
    if command -v "$candidate" >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

PYTHON_BIN="$(find_python || true)"
if [ -z "$PYTHON_BIN" ]; then
  echo "[G0] python3/python is required for version metadata verification" >&2
  exit 1
fi

"$PYTHON_BIN" - "$PROJECT_ROOT" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
version = (root / "VERSION").read_text(encoding="utf-8").strip()
manifest = json.loads((root / "release" / "version.json").read_text(encoding="utf-8"))
errors = []

if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?", version):
    errors.append(f"VERSION must be SemVer, got {version!r}")
if manifest.get("version") != version:
    errors.append(f"release/version.json version {manifest.get('version')!r} must equal VERSION {version!r}")
if manifest.get("schemaVersion") != 1:
    errors.append("release/version.json schemaVersion must be 1")
for name, service_version in (manifest.get("services") or {}).items():
    if service_version != version:
        errors.append(f"service {name!r} version {service_version!r} must equal VERSION {version!r}")

checks = []
for p in root.rglob("package.json"):
    if "node_modules" in p.parts: continue
    try:
        pkg = json.loads(p.read_text(encoding="utf-8"))
        if "version" in pkg:
            checks.append((str(p.relative_to(root)), pkg["version"]))
    except:
        pass

for p in root.rglob("tauri.conf.json"):
    if "node_modules" in p.parts or "target" in p.parts: continue
    try:
        tauri = json.loads(p.read_text(encoding="utf-8"))
        if "version" in tauri:
            checks.append((str(p.relative_to(root)), tauri["version"]))
    except:
        pass

for label, value in checks:
    if value != version:
        errors.append(f"{label} version {value!r} must equal VERSION {version!r}")

if errors:
    print("[G0] version check failed:")
    for err in errors:
        print(f"  - {err}")
    raise SystemExit(1)

print(f"[G0] version check passed: {version}")
PY

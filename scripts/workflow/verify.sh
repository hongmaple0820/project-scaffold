#!/usr/bin/env bash
# Profile-aware repository verification.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$PROJECT_ROOT/.agent/project.json"
STATE_FILE="$PROJECT_ROOT/.agent/state/current.json"
PY_STATE="$PROJECT_ROOT/scripts/lib/workflow_state.py"
PROFILE="default"
SERVICE=""
LIST=false

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/workflow/verify.sh [--profile default|backend|ui|all|scaffold] [--service name] [--list]
  bash scripts/workflow/verify.sh [service_name|all]
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --service)
      SERVICE="${2:-}"
      shift 2
      ;;
    --list)
      LIST=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "[VERIFY] unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
    all)
      PROFILE="all"
      shift
      ;;
    *)
      SERVICE="$1"
      shift
      ;;
  esac
done

if [ ! -f "$CONFIG" ]; then
  echo "[VERIFY] missing .agent/project.json"
  exit 1
fi

if [ "$LIST" = true ]; then
  python3 - "$CONFIG" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    cfg = json.load(f)

print("profiles:")
for name, profile in sorted((cfg.get("profiles") or {}).items()):
    print(f"  - {name}: {profile.get('description', '')}")

print("services:")
for name, service in sorted((cfg.get("services") or {}).items()):
    print(f"  - {name}: {service.get('path', '.')}")
PY
  exit 0
fi

if [ "$PROFILE" = "scaffold" ] && [ -z "$SERVICE" ]; then
  bash "$PROJECT_ROOT/scripts/validate-config.sh"
  bash "$PROJECT_ROOT/scripts/gates/all.sh" --dry-run
  echo "[VERIFY] profile scaffold passed"
  exit 0
fi

PLAN="$(
python3 - "$CONFIG" "$PROFILE" "$SERVICE" <<'PY'
import json
import sys

config_path, profile_name, selected_service = sys.argv[1:4]
with open(config_path, encoding="utf-8") as f:
    cfg = json.load(f)

profiles = cfg.get("profiles") or {}
services = cfg.get("services") or {}
stacks = cfg.get("stacks") or {}

if selected_service:
    service_names = [selected_service]
    checks = (profiles.get(profile_name) or {}).get("checks") or ["build", "lint", "test"]
else:
    profile = profiles.get(profile_name)
    if profile is None:
        print(f"ERROR\tunknown profile: {profile_name}")
        raise SystemExit(0)
    service_names = profile.get("services") or []
    checks = profile.get("checks") or ["build", "lint", "test"]
    if service_names == "*":
        service_names = sorted(services.keys())

if not service_names:
    print(f"ERROR\tprofile has no services: {profile_name}")
    raise SystemExit(0)

for name in service_names:
    service = services.get(name)
    if not service:
        print(f"ERROR\tunknown service: {name}")
        continue
    stack_name = service.get("stack") or "custom"
    stack = stacks.get(stack_name) or {}
    commands = dict(stack.get("commands") or {})
    commands.update(service.get("commands") or {})
    required_tools = dict(stack.get("required_tools") or {})
    required_tools.update(service.get("required_tools") or {})
    path = service.get("path") or "."
    for check in checks:
        command = commands.get(check)
        if not command:
            print(f"SKIP\t{name}\t{path}\t{check}\tno command configured")
            continue
        tools = ",".join(required_tools.get(check) or []) or "-"
        print(f"RUN\t{name}\t{path}\t{check}\t{tools}\t{command}")
PY
)"

STATUS=0
while IFS=$'\t' read -r kind name path check tools command; do
  [ -z "$kind" ] && continue
  case "$kind" in
    ERROR)
      echo "[VERIFY] $name"
      STATUS=1
      ;;
    SKIP)
      echo "[VERIFY] skip $name/$check: $command"
      ;;
    RUN)
      IFS=',' read -ra tool_list <<< "$tools"
      MISSING_TOOL=0
      for tool in "${tool_list[@]}"; do
        if [ "$tool" = "go" ] && command -v go.exe >/dev/null 2>&1; then
          continue
        fi
        if [ -n "$tool" ] && [ "$tool" != "-" ] && ! command -v "$tool" >/dev/null 2>&1; then
          echo "[VERIFY] missing tool for $name/$check: $tool"
          MISSING_TOOL=1
          STATUS=1
        fi
      done
      if [ "$MISSING_TOOL" -ne 0 ]; then
        continue
      fi
      log_dir="$PROJECT_ROOT/.agent/logs/$name"
      mkdir -p "$log_dir"
      echo "[VERIFY] run $name/$check"
      if ! (cd "$PROJECT_ROOT/$path" && bash -lc "$command") >"$log_dir/$check.profile.log" 2>&1 < /dev/null; then
        echo "[VERIFY] failed $name/$check; log: .agent/logs/$name/$check.profile.log"
        STATUS=1
      fi
      ;;
  esac
done <<< "$PLAN"

if [ "$STATUS" -ne 0 ]; then
  echo "[VERIFY] failed"
  exit "$STATUS"
fi

if [ -f "$STATE_FILE" ]; then
  python3 "$PY_STATE" add-gates "$STATE_FILE" G4 G5 G6 G7 2>/dev/null || true
fi

echo "[VERIFY] profile passed: $PROFILE${SERVICE:+ service=$SERVICE}"

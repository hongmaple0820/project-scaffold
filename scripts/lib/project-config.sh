#!/bin/bash
# scripts/lib/project-config.sh
# 读取 .agent/project.json，为门控提供技术栈和命令配置。

if [ -z "${PROJECT_ROOT:-}" ]; then
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

PROJECT_CONFIG_FILE="$PROJECT_ROOT/.agent/project.json"

require_project_config() {
    if [ ! -f "$PROJECT_CONFIG_FILE" ]; then
        echo "[CONFIG] ❌ 缺少项目配置: .agent/project.json"
        exit 1
    fi
    if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
        echo "[CONFIG] ❌ 缺少 jq 或 python3，无法读取 .agent/project.json"
        exit 1
    fi
}

configured_stack() {
    require_project_config
    if command -v jq >/dev/null 2>&1; then
        jq -r '.stack // "auto"' "$PROJECT_CONFIG_FILE"
    else
        python3 - "$PROJECT_CONFIG_FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
print(data.get("stack") or "auto")
PY
    fi
}

detect_stack() {
    require_project_config

    local selected
    selected="$(configured_stack)"
    if [ "$selected" != "auto" ] && [ "$selected" != "null" ] && [ -n "$selected" ]; then
        echo "$selected"
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        python3 - "$PROJECT_CONFIG_FILE" "$PROJECT_ROOT" <<'PY'
import json, pathlib, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
root = pathlib.Path(sys.argv[2])
for stack, cfg in (data.get("stacks") or {}).items():
    for marker in cfg.get("detect") or []:
        if (root / marker).exists():
            print(stack)
            raise SystemExit(0)
print("none")
PY
        return 0
    fi

    while IFS= read -r stack; do
        while IFS= read -r marker; do
            if [ -e "$PROJECT_ROOT/$marker" ]; then
                echo "$stack"
                return 0
            fi
        done < <(jq -r --arg stack "$stack" '.stacks[$stack].detect[]?' "$PROJECT_CONFIG_FILE")
    done < <(jq -r '.stacks | keys[]' "$PROJECT_CONFIG_FILE")

    echo "none"
}

stack_exists() {
    local stack="$1"
    require_project_config
    if command -v jq >/dev/null 2>&1; then
        jq -e --arg stack "$stack" '.stacks[$stack] != null' "$PROJECT_CONFIG_FILE" >/dev/null
    else
        python3 - "$PROJECT_CONFIG_FILE" "$stack" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
raise SystemExit(0 if sys.argv[2] in (data.get("stacks") or {}) else 1)
PY
    fi
}

gate_command() {
    local stack="$1"
    local gate="$2"
    require_project_config
    if command -v jq >/dev/null 2>&1; then
        jq -r --arg stack "$stack" --arg gate "$gate" '.stacks[$stack].commands[$gate] // empty' "$PROJECT_CONFIG_FILE"
    else
        python3 - "$PROJECT_CONFIG_FILE" "$stack" "$gate" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
print(((data.get("stacks") or {}).get(sys.argv[2]) or {}).get("commands", {}).get(sys.argv[3], ""))
PY
    fi
}

coverage_threshold() {
    require_project_config
    if command -v jq >/dev/null 2>&1; then
        jq -r '.coverage_threshold // 80' "$PROJECT_CONFIG_FILE"
    else
        python3 - "$PROJECT_CONFIG_FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
print(data.get("coverage_threshold") or 80)
PY
    fi
}

required_tools() {
    local stack="$1"
    local gate="$2"
    require_project_config
    if command -v jq >/dev/null 2>&1; then
        jq -r --arg stack "$stack" --arg gate "$gate" '(.stacks[$stack].required_tools[$gate] // [])[]' "$PROJECT_CONFIG_FILE"
    else
        python3 - "$PROJECT_CONFIG_FILE" "$stack" "$gate" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
tools = (((data.get("stacks") or {}).get(sys.argv[2]) or {}).get("required_tools", {}).get(sys.argv[3]) or [])
print("\n".join(tools))
PY
    fi
}

check_required_tools() {
    local stack="$1"
    local gate="$2"
    local missing=0

    while IFS= read -r tool; do
        if [ -n "$tool" ] && ! command -v "$tool" >/dev/null 2>&1; then
            echo "[$gate] ❌ 缺少工具: $tool"
            missing=$((missing+1))
        fi
    done < <(required_tools "$stack" "$gate")

    if [ "$missing" -gt 0 ]; then
        return 1
    fi
}

run_gate_command() {
    local stack="$1"
    local gate="$2"
    local command="$3"
    local label="${4:-$gate}"

    if [ -z "$command" ]; then
        echo "[$label] ℹ️ $stack 未配置 $gate 命令，门控不适用"
        return 0
    fi

    check_required_tools "$stack" "$gate"
    mkdir -p "$PROJECT_ROOT/.agent/logs"
    (cd "$PROJECT_ROOT" && bash -lc "$command")
}

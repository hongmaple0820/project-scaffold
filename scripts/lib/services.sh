#!/bin/bash
# Shared product service matrix for repository-level gates.

set -e

if [ -z "${PROJECT_ROOT:-}" ]; then
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

go_cmd() {
    local found candidate
    found="$(command -v go 2>/dev/null || true)"
    if [ -n "$found" ]; then
        case "$found" in
            *.exe) candidate="go.exe" ;;
            *) candidate="go" ;;
        esac
        if "$candidate" version >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    fi

    if command -v go.exe >/dev/null 2>&1 && go.exe version >/dev/null 2>&1; then
        echo "go.exe"
    else
        echo ""
    fi
}

product_services() {
    # Dynamically find directories containing go.mod, ignoring vendor and hidden directories
    # If no services found, print a warning to stderr and return nothing
    local count=0
    while IFS= read -r modfile; do
        if [ -n "$modfile" ]; then
            basename "$(dirname "$modfile")"
            count=$((count + 1))
        fi
    done < <(find "$PROJECT_ROOT" -mindepth 1 -name "go.mod" -not -path "*/vendor/*" -not -path "*/\.*" 2>/dev/null || true)
    
    if [ "$count" -eq 0 ]; then
        # When used in scaffold without any services, fallback to a placeholder or empty
        echo "placeholder-service"
    fi
}

service_dir() {
    local service="$1"
    if [ "$service" = "placeholder-service" ]; then
        echo "$PROJECT_ROOT/$service"
        return 0
    fi
    # Assume service is a directory under PROJECT_ROOT
    # Find the actual path
    local found_dir
    found_dir=$(find "$PROJECT_ROOT" -mindepth 1 -maxdepth 3 -type d -name "$service" 2>/dev/null | head -n 1)
    if [ -n "$found_dir" ]; then
        echo "$found_dir"
    else
        echo "$PROJECT_ROOT/$service"
    fi
}

service_entrypoint() {
    local service="$1"
    local dir
    dir="$(service_dir "$service")"
    if [ -f "$dir/main.go" ]; then
        echo "main.go"
    elif [ -f "$dir/${service}.go" ]; then
        echo "${service}.go"
    else
        # default guess
        echo "main.go"
    fi
}

selected_services() {
    if [ "$#" -eq 0 ] || [ "${1:-}" = "all" ]; then
        product_services
        return 0
    fi

    local has_all=false
    local services=()
    for s in "$@"; do
        if [ "$s" = "all" ]; then
            has_all=true
        else
            services+=("$s")
        fi
    done

    if [ "$has_all" = true ]; then
        product_services
    else
        for s in "${services[@]}"; do
            echo "$s"
        done | sort -u
    fi
}

service_log_dir() {
    local service="$1"
    echo "$PROJECT_ROOT/.agent/logs/$service"
}

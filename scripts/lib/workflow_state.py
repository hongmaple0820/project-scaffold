#!/usr/bin/env python3
"""Small helper for .agent/state/current.json.

The workflow scripts run in Git Bash/WSL/PowerShell-adjacent environments where
`jq` is not always installed. Keep canonical state reads/writes in Python's
standard library.
"""

from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load(path: Path) -> dict:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as fh:
        try:
            data = json.load(fh)
        except json.JSONDecodeError:
            return {}
    return data if isinstance(data, dict) else {}


def save(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    tmp.replace(path)


def default_state(task_id: str = "", level: str = "M") -> dict:
    return {
        "task_id": task_id,
        "level": level,
        "phase": "explore",
        "artifacts_dir": "",
        "runtime_contract": "",
        "reality_check": "",
        "resource_cleanup": "",
        "explored_files": [],
        "file_count": 0,
        "main_contradiction": "",
        "completed_gates": [],
        "open_tasks": [],
        "files_modified": [],
        "updated_at": now(),
    }


def cmd_init(args: list[str]) -> int:
    state_path = Path(args[0])
    task_id, level, artifacts_dir = args[1], args[2], args[3]
    data = default_state(task_id, level)
    data["artifacts_dir"] = artifacts_dir
    data["runtime_contract"] = str(Path(artifacts_dir) / "runtime.md")
    data["reality_check"] = str(Path(artifacts_dir) / "reality-check.md")
    data["resource_cleanup"] = str(Path(artifacts_dir) / "resource-cleanup.md")
    save(state_path, data)
    return 0


def cmd_explore(args: list[str]) -> int:
    state_path = Path(args[0])
    detail_path = Path(args[1])
    contradiction = args[2]
    files = args[3:]
    stamp = now()

    detail = {
        "updated_at": stamp,
        "files": files,
        "file_count": len(files),
        "graphify_read": False,
        "graph_nodes": 0,
        "main_contradiction": contradiction,
        "skills_checked": True,
    }

    project_root = state_path.parents[2]
    graph_path = project_root / "graphify-out" / "graph.json"
    if graph_path.exists():
        detail["graphify_read"] = True
        try:
            graph = json.loads(graph_path.read_text(encoding="utf-8"))
            detail["graph_nodes"] = len(graph.get("nodes", []))
        except Exception:
            detail["graph_nodes"] = 0

    save(detail_path, detail)

    data = load(state_path) or default_state(
        task_id="ad-hoc-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"),
        level="M",
    )
    data["phase"] = "explore"
    data["explored_files"] = files
    data["file_count"] = len(files)
    data["main_contradiction"] = contradiction
    data["updated_at"] = stamp
    save(state_path, data)
    return 0


def cmd_plan(args: list[str]) -> int:
    state_path = Path(args[0])
    task_id, level, artifacts_dir = args[1], args[2], args[3]
    data = load(state_path) or default_state(task_id, level)
    data.update(
        {
            "task_id": task_id,
            "level": level,
            "phase": "plan",
            "artifacts_dir": artifacts_dir,
            "runtime_contract": str(Path(artifacts_dir) / "runtime.md"),
            "reality_check": str(Path(artifacts_dir) / "reality-check.md"),
            "resource_cleanup": str(Path(artifacts_dir) / "resource-cleanup.md"),
            "updated_at": now(),
        }
    )
    save(state_path, data)
    return 0


def cmd_checkpoint(args: list[str]) -> int:
    state_path = Path(args[0])
    project_root = Path(args[1])
    phase = args[2]
    data = load(state_path) or default_state(
        task_id="ad-hoc-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"),
        level="M",
    )
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only"],
            cwd=project_root,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        files = [line for line in result.stdout.splitlines() if line]
    except Exception:
        files = []
    data["phase"] = phase
    data["files_modified"] = files
    data["updated_at"] = now()
    data.setdefault("completed_gates", [])
    data.setdefault("open_tasks", [])
    save(state_path, data)
    return 0


def cmd_get(args: list[str]) -> int:
    data = load(Path(args[0]))
    key = args[1]
    default = args[2] if len(args) > 2 else ""
    value = data.get(key, default)
    if isinstance(value, list):
        print(", ".join(str(item) for item in value))
    else:
        print(value)
    return 0


def cmd_len(args: list[str]) -> int:
    data = load(Path(args[0]))
    value = data.get(args[1], [])
    if isinstance(value, list):
        print(len(value))
    else:
        print(int(value or 0))
    return 0


def cmd_add_gates(args: list[str]) -> int:
    state_path = Path(args[0])
    gates = args[1:]
    data = load(state_path)
    existing = data.get("completed_gates", [])
    if not isinstance(existing, list):
        existing = []
    data["completed_gates"] = sorted(set(str(item) for item in existing + gates))
    data["phase"] = "verify"
    data["updated_at"] = now()
    save(state_path, data)
    return 0


COMMANDS = {
    "init": cmd_init,
    "explore": cmd_explore,
    "plan": cmd_plan,
    "checkpoint": cmd_checkpoint,
    "get": cmd_get,
    "len": cmd_len,
    "add-gates": cmd_add_gates,
}


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] not in COMMANDS:
        print("usage: workflow_state.py <command> ...", file=sys.stderr)
        return 2
    return COMMANDS[argv[1]](argv[2:])


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

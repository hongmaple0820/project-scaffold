#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PS_FILE="$ROOT/scripts/workflow/verify.ps1"
if command -v wslpath >/dev/null 2>&1 && [[ "$PS_FILE" == /mnt/* ]]; then
  PS_FILE="$(wslpath -w "$PS_FILE")"
fi
if command -v powershell.exe >/dev/null 2>&1 && powershell.exe -NoProfile -Command "exit 0" >/dev/null 2>&1; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS_FILE"
elif command -v powershell >/dev/null 2>&1 && powershell -NoProfile -Command "exit 0" >/dev/null 2>&1; then
  powershell -NoProfile -ExecutionPolicy Bypass -File "$PS_FILE"
else
  echo "[G5] PowerShell not runnable from this shell; run scripts/workflow/verify.ps1 in PowerShell-capable environments"
fi
echo "[G5] scaffold self-check completed"

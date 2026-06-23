#!/usr/bin/env sh
set -eu

SCALE_VERSION="${SCALE_VERSION:-0.50.11}"
SCALE_PREFLIGHT_ARGS="${SCALE_PREFLIGHT_ARGS:---service all --preflight-profile quick}"

if command -v scale >/dev/null 2>&1; then
  scale preflight $SCALE_PREFLIGHT_ARGS
else
  npx --yes "@hongmaple0820/scale-engine@$SCALE_VERSION" preflight $SCALE_PREFLIGHT_ARGS
fi

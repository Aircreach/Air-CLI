#!/usr/bin/env bash
set -euo pipefail

UI_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
AIR_HOME="${AIR_HOME:-${UI_HOME%/ui}}"
export AIR_HOME

if ! command -v go >/dev/null 2>&1; then
    printf 'air-ui: go is required to build the helper\n' >&2
    exit 1
fi

mkdir -p "$UI_HOME/bin"
cd "$UI_HOME/helper"
go build -o "$UI_HOME/bin/air-ui" .
printf 'built %s\n' "$UI_HOME/bin/air-ui"

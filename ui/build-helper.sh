#!/usr/bin/env bash
set -euo pipefail

UI_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
AIR_HOME="${AIR_HOME:-${UI_HOME%/ui}}"
export AIR_HOME

# shellcheck disable=SC1090
[ -r "$AIR_HOME/air.bash" ] && . "$AIR_HOME/air.bash"

if ! command -v go >/dev/null 2>&1; then
    printf 'air-ui: go is required to build the helper\n' >&2
    exit 1
fi

target="$(ui_helper_path)"
mkdir -p "$(dirname "$target")"
cd "$UI_HOME/helper"
go build -o "$target" .
printf 'built %s\n' "$target"

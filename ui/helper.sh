# Air UI helper adapter.

ui_helper_path() {
    if [ -n "${AIR_UI_HELPER:-}" ]; then
        printf '%s\n' "$AIR_UI_HELPER"
    else
        printf '%s\n' "$(ui_path bin/air-ui)"
    fi
}

ui_helper_installed() {
    [ -x "$(ui_helper_path)" ]
}

ui_helper_can_build() {
    [ -r "$(ui_path helper/go.mod)" ] || return 1
    [ -r "$(ui_path helper/main.go)" ] || return 1
    command -v go >/dev/null 2>&1
}

ui_helper_available() {
    local helper

    [ "${AIR_UI_CLI:-0}" = "1" ] || return 1
    ui_helper_mode_enabled || return 1
    [ "${AIR_UI_HELPER_ENABLED:-1}" != "0" ] || return 1
    ui_is_plain && return 1
    ui_is_interactive || return 1
    helper="$(ui_helper_path)"
    [ -x "$helper" ]
}

ui_helper_build() {
    bash "$(ui_path build-helper.sh)"
}

ui_helper() {
    local helper

    helper="$(ui_helper_path)"
    AIR_PLAIN="${AIR_PLAIN:-0}" \
    NO_COLOR="${NO_COLOR:-}" \
    AIR_NON_INTERACTIVE="${AIR_NON_INTERACTIVE:-0}" \
    AIR_YES="${AIR_YES:-0}" \
    AIR_UI_DENSITY="${AIR_UI_DENSITY:-normal}" \
    AIR_UI_COLOR_TITLE="${AIR_UI_COLOR_TITLE:-1}" \
    AIR_UI_COLOR_MUTED="${AIR_UI_COLOR_MUTED:-2;37}" \
    AIR_UI_COLOR_OK="${AIR_UI_COLOR_OK:-1;32}" \
    AIR_UI_COLOR_WARNING="${AIR_UI_COLOR_WARNING:-1;33}" \
    AIR_UI_COLOR_ERROR="${AIR_UI_COLOR_ERROR:-1;31}" \
    AIR_UI_COLOR_HINT="${AIR_UI_COLOR_HINT:-1;36}" \
    "$helper" "$@"
}

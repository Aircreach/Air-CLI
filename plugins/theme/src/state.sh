# Theme settings and state helpers.

theme_settings_path() {
    plugin_settings_path theme
}

theme_state_path() {
    plugin_state_path theme
}

theme_data_dir() {
    plugin_data_dir theme
}

theme_ensure_settings() {
    plugin_ensure_settings theme
}

theme_ensure_state() {
    local state

    mkdir -p "$(theme_data_dir)"
    state="$(theme_state_path)"
    [ -e "$state" ] && return 0

    cat > "$state" <<'EOF'
AIR_THEME_CURRENT=focus
AIR_THEME_RENDERER=starship
EOF
}

theme_load_config() {
    theme_load_settings "$@"
}

theme_load_settings() {
    theme_ensure_settings
    # shellcheck disable=SC1090
    . "$(theme_settings_path)"

    case "${AIR_THEME_PATH_DEPTH:-3}" in
        1|2|3) ;;
        *) AIR_THEME_PATH_DEPTH=3 ;;
    esac

    case "${AIR_THEME_PATH_SEGMENT_MAX:-18}" in
        ''|*[!0-9]*) AIR_THEME_PATH_SEGMENT_MAX=18 ;;
    esac

    AIR_THEME_PATH_ELLIPSIS="${AIR_THEME_PATH_ELLIPSIS:-…}"
    AIR_THEME_PATH_ICON="${AIR_THEME_PATH_ICON:-}"
    AIR_THEME_PATH_HOME="${AIR_THEME_PATH_HOME:-~}"

    if [ "${AIR_THEME_PATH_SEGMENT_MAX:-18}" = "0" ]; then
        AIR_THEME_PATH_SEGMENT_ENABLED=0
    else
        AIR_THEME_PATH_SEGMENT_ENABLED=1
    fi
}

theme_load_state() {
    theme_ensure_state
    # shellcheck disable=SC1090
    . "$(theme_state_path)"

    if ! theme_renderer_exists "${AIR_THEME_RENDERER:-starship}"; then
        AIR_THEME_RENDERER=starship
    fi

    if ! theme_name "${AIR_THEME_CURRENT:-focus}" "$AIR_THEME_RENDERER" >/dev/null 2>&1; then
        AIR_THEME_CURRENT="$(theme_names "$AIR_THEME_RENDERER" | sed -n '1p')"
        AIR_THEME_CURRENT="${AIR_THEME_CURRENT:-focus}"
    fi
}

theme_save_state() {
    local theme="$1"
    local renderer="$2"

    mkdir -p "$(theme_data_dir)"
    cat > "$(theme_state_path)" <<EOF
AIR_THEME_CURRENT=$theme
AIR_THEME_RENDERER=$renderer
EOF
}

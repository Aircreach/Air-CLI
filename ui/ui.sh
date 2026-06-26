# Air root CLI UI subsystem.

AIR_UI_LOADED=1

ui_air_home() {
    if declare -F air_home >/dev/null 2>&1; then
        air_home
        return 0
    fi
    printf '%s\n' "${AIR_HOME:-$HOME/.local/share/air}"
}

ui_user_home() {
    if [ -n "${AIR_USER_HOME:-}" ]; then
        printf '%s\n' "$AIR_USER_HOME"
        return 0
    fi
    if declare -F air_user_home >/dev/null 2>&1; then
        air_user_home
        return 0
    fi
    printf '%s\n' "${HOME:-/root}/.air"
}

ui_home() {
    printf '%s\n' "${AIR_UI_HOME:-$(ui_air_home)/ui}"
}

ui_config_home() {
    if [ -n "${AIR_UI_CONFIG_HOME:-}" ]; then
        printf '%s\n' "$AIR_UI_CONFIG_HOME"
        return 0
    fi
    if declare -F air_config_home >/dev/null 2>&1; then
        printf '%s\n' "$(air_config_home)/ui"
        return 0
    fi
    printf '%s\n' "${AIR_CONFIG_HOME:-$(ui_user_home)/config}/ui"
}

ui_state_home() {
    if [ -n "${AIR_UI_STATE_HOME:-}" ]; then
        printf '%s\n' "$AIR_UI_STATE_HOME"
        return 0
    fi
    if declare -F air_state_home >/dev/null 2>&1; then
        printf '%s\n' "$(air_state_home)/ui"
        return 0
    fi
    printf '%s\n' "${AIR_STATE_HOME:-$(ui_user_home)/state}/ui"
}

ui_cache_home() {
    if [ -n "${AIR_UI_CACHE_HOME:-}" ]; then
        printf '%s\n' "$AIR_UI_CACHE_HOME"
        return 0
    fi
    if declare -F air_cache_home >/dev/null 2>&1; then
        printf '%s\n' "$(air_cache_home)/ui"
        return 0
    fi
    printf '%s\n' "${AIR_CACHE_HOME:-$(ui_user_home)/cache}/ui"
}

ui_runtime_home() {
    if [ -n "${AIR_UI_RUNTIME_HOME:-}" ]; then
        printf '%s\n' "$AIR_UI_RUNTIME_HOME"
        return 0
    fi
    if declare -F air_runtime_home >/dev/null 2>&1; then
        printf '%s\n' "$(air_runtime_home)/ui"
        return 0
    fi
    printf '%s\n' "${AIR_RUNTIME_HOME:-$(ui_user_home)/runtime}/ui"
}

ui_log_home() {
    if [ -n "${AIR_UI_LOG_HOME:-}" ]; then
        printf '%s\n' "$AIR_UI_LOG_HOME"
        return 0
    fi
    if declare -F air_log_home >/dev/null 2>&1; then
        printf '%s\n' "$(air_log_home)/ui"
        return 0
    fi
    printf '%s\n' "${AIR_LOG_HOME:-$(ui_user_home)/logs}/ui"
}

ui_path() {
    local rel="$1"

    printf '%s\n' "$(ui_home)/$rel"
}

_air_ui_source() {
    local file="$1"

    [ -r "$file" ] && . "$file"
}

_air_ui_source "$(ui_air_home)/lib/terminal.sh"
_air_ui_source "$(ui_path themes/default.sh)"
_air_ui_source "$(ui_path context.sh)"
_air_ui_source "$(ui_path state.sh)"
_air_ui_source "$(ui_path helper.sh)"
_air_ui_source "$(ui_path components.sh)"

ui() {
    local command="${1:-}"

    shift || true
    case "$command" in
        -h|--help|help|'') ui_help "$@" ;;
        block|status) ui_block "$@" ;;
        badge|pill) ui_badge "$@" ;;
        check-item) ui_check_item "$@" ;;
        color) ui_color "$@" ;;
        command-help) ui_command_help "$@" ;;
        confirm) ui_confirm "$@" ;;
        effects|effect|fx) ui_effects "$@" ;;
        example) ui_example "$@" ;;
        flow) ui_flow "$@" ;;
        helper|helper-status) ui_helper_status "$@" ;;
        code) ui_code "$@" ;;
        hr|rule) ui_hr "$@" ;;
        input) ui_input "$@" ;;
        kv) ui_kv "$@" ;;
        layout) ui_layout "$@" ;;
        list) ui_list "$@" ;;
        log) ui_log "$@" ;;
        loading|spinner) ui_spinner "$@" ;;
        markdown|md) ui_markdown "$@" ;;
        marker) ui_marker "$@" ;;
        multiselect) ui_multiselect "$@" ;;
        overlay) ui_overlay "$@" ;;
        modal|dialog) ui_overlay modal "$@" ;;
        panel) ui_panel "$@" ;;
        popover) ui_overlay popover "$@" ;;
        password) ui_password "$@" ;;
        progress) ui_progress "$@" ;;
        select) ui_select "$@" ;;
        spacer) ui_spacer "$@" ;;
        step) ui_step "$@" ;;
        summary) ui_summary "$@" ;;
        table) ui_table "$@" ;;
        task) ui_task "$@" ;;
        text) ui_text "$@" ;;
        toast) ui_overlay toast "$@" ;;
        tooltip) ui_overlay tooltip "$@" ;;
        title) ui_title "$@" ;;
        *)
            if command -v log_error >/dev/null 2>&1; then
                log_error "ui: unknown command: $command"
            else
                printf 'error ui: unknown command: %s\n' "$command" >&2
            fi
            return 1
            ;;
    esac
}

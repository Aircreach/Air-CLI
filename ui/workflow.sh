# Air UI workflow helpers shared by core and plugins.

ui_check_item() {
    if [ "${1:-}" = "example" ]; then
        ui_check_item ok "manifest" "plugin.toml is readable."
        ui_check_item warning "renderer" "Optional helper is missing; fallback is active."
        ui_check_item blocked "write state" "Fix errors before commit."
        return 0
    fi

    local severity="${1:-hint}" title="${2:-}" message="${3:-}"

    case "$severity" in
        success|passed|ready) severity=ok ;;
        warn) severity=warning ;;
        failed|err) severity=error ;;
    esac
    ui block "$severity" "$title" "$message"
}

ui_log() {
    if [ "${1:-}" = "example" ]; then
        ui_log success "Runtime generated"
        ui_log warning "Using fallback renderer"
        ui_log error "Missing required handler"
        return 0
    fi

    local severity="${1:-info}" message

    shift || true
    message="$*"
    case "$severity" in
        ok|success) ui block ok "$message" "" ;;
        warn|warning) ui block warning "$message" "" ;;
        error|err) ui block error "$message" "" ;;
        blocked) ui block blocked "$message" "" ;;
        hint|info|*) ui block hint "$message" "" ;;
    esac
}

ui_command_help() {
    if [ "$#" -gt 0 ]; then
        ui markdown "$*"
    else
        ui markdown
    fi
}

# Air CLI UI status blocks.

ui_block_symbol() {
    case "$1" in
        ok|success) ui_icon done ;;
        warning|warn) ui_icon warning ;;
        *) ui_icon "$1" ;;
    esac
}

ui_block_color() {
    case "$1" in
        ok) printf '%s\n' "$AIR_UI_COLOR_OK" ;;
        warning|warn) printf '%s\n' "$AIR_UI_COLOR_WARNING" ;;
        error) printf '%s\n' "$AIR_UI_COLOR_ERROR" ;;
        blocked) printf '%s\n' "$AIR_UI_COLOR_BLOCKED" ;;
        hint|info) printf '%s\n' "$AIR_UI_COLOR_HINT" ;;
        *) printf '%s\n' "$AIR_UI_COLOR_MUTED" ;;
    esac
}

ui_block() {
    if [ "${1:-}" = "example" ]; then
        ui_block ok "OK block" "A completed operation."
        ui_block warning "Warning block" "A recoverable issue that needs confirmation."
        ui_block error "Error block" "A command cannot continue until this is fixed."
        ui_block blocked "Blocked block" "A safety check refused to write state."
        ui_block hint "Hint block" "A non-critical suggestion for the next step."
        return 0
    fi

    local severity="${1:-info}" title="${2:-}" message="${3:-}" color symbol severity_label

    color="$(ui_block_color "$severity")"
    case "$severity" in
        ok|success) severity_label=done ;;
        warning) severity_label=warn ;;
        *) severity_label="$severity" ;;
    esac
    symbol="$(ui_block_symbol "$severity")"
    printf '  '
    if ui_supports_color; then
        ui_color "$color" "$symbol"
        printf ' '
        ui_badge "$severity_label" "$severity"
    else
        ui marker "$severity_label" --style text
    fi
    [ -n "$title" ] && {
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "$title"
    }
    printf '\n'
    if [ -n "$message" ]; then
        printf '%s\n' "$message" | while IFS= read -r line; do
            printf '    '
            ui_text "$line"
        done
    fi
}

ui_status() {
    ui_block "$@"
}

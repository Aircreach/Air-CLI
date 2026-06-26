# Air UI marker component.

ui_marker_color() {
    case "${1:-hint}" in
        done|ok|success) printf '%s\n' "$AIR_UI_COLOR_OK" ;;
        warn|warning) printf '%s\n' "$AIR_UI_COLOR_WARNING" ;;
        error|failed) printf '%s\n' "$AIR_UI_COLOR_ERROR" ;;
        blocked) printf '%s\n' "$AIR_UI_COLOR_BLOCKED" ;;
        current|select) printf '%s\n' "$AIR_UI_COLOR_ACCENT" ;;
        pending|empty|none) printf '%s\n' "$AIR_UI_COLOR_MUTED" ;;
        hint|info|*) printf '%s\n' "$AIR_UI_COLOR_HINT" ;;
    esac
}

ui_marker_glyph() {
    case "${1:-pending}" in
        done|ok|success) printf '%s\n' '✔' ;;
        warn|warning) printf '%s\n' '!' ;;
        error|failed) printf '%s\n' '×' ;;
        blocked) printf '%s\n' '■' ;;
        current|select) printf '%s\n' '→' ;;
        pending|empty|none) printf '%s\n' ' ' ;;
        hint|info) printf '%s\n' '·' ;;
        *) printf '%s\n' "$1" ;;
    esac
}

ui_marker_label() {
    case "${1:-pending}" in
        done|ok|success) printf '%s\n' 'DONE' ;;
        warn|warning) printf '%s\n' 'WARN' ;;
        error|failed) printf '%s\n' 'ERROR' ;;
        blocked) printf '%s\n' 'BLOCKED' ;;
        current|select) printf '%s\n' 'NOW' ;;
        pending|empty|none) printf '%s\n' 'PENDING' ;;
        hint|info) printf '%s\n' 'INFO' ;;
        *) printf '%s\n' "$1" ;;
    esac
}

ui_marker() {
    local state="${1:-pending}" style="bracket" color glyph label

    [ "$#" -gt 0 ] && shift
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --style)
                style="${2:-bracket}"
                shift 2
                ;;
            --*)
                ui check-item error "ui marker" "Unknown option: $1"
                return 1
                ;;
            *)
                state="$1"
                shift
                ;;
        esac
    done

    color="$(ui_marker_color "$state")"
    glyph="$(ui_marker_glyph "$state")"
    label="$(ui_marker_label "$state")"

    case "$style" in
        text)
            ui_color "$color" "$label"
            ;;
        bare|glyph|icon)
            ui_color "$color" "$glyph"
            ;;
        bracket|slot|*)
            if ui_icon_enabled; then
                ui_color "$color" "[$glyph ]"
            else
                ui_color "$color" "[$label]"
            fi
            ;;
    esac
}

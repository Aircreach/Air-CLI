# Air UI overlay-style components. These simulate terminal overlays with panels.

ui_overlay_help() {
    ui command-help <<'EOF'
# ui overlay

Terminal overlay patterns with plain fallbacks.

Usage:
  ui overlay <component> [options]

Components:
  modal       Important decision or summary panel
  tooltip     Explicit hint/callout near nearby text
  toast       Short status message
  popover     Compact contextual panel
  example     Run the component story

Notes:
  Terminal UIs do not have native hover. Tooltip means an explicit hint/callout
  rendered by the command at the moment it is useful.
EOF
}

ui_overlay_modal() {
    local title="Dialog" severity="hint" content=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --title)
                title="${2:-Dialog}"
                shift 2
                ;;
            --severity|--style)
                severity="${2:-hint}"
                shift 2
                ;;
            *)
                content="${content}${content:+
}$1"
                shift
                ;;
        esac
    done
    if [ -z "$content" ] && [ ! -t 0 ]; then
        content="$(cat)"
    fi
    ui panel --title "$title" --severity "$severity" "$content"
}

ui_overlay_tooltip() {
    local target="" text="" severity="hint"

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target)
                target="${2:-}"
                shift 2
                ;;
            --text|--message)
                text="${2:-}"
                shift 2
                ;;
            --severity|--style)
                severity="${2:-hint}"
                shift 2
                ;;
            *)
                text="${text}${text:+ }$1"
                shift
                ;;
        esac
    done
    [ -n "$target" ] && {
        printf '  '
        ui_color "$AIR_UI_COLOR_TITLE" "$target"
        printf '\n'
    }
    printf '  '
    ui_color "$(ui_severity_color "$severity")" "└─"
    printf ' '
    ui_text "${text:-Helpful context appears here.}"
}

ui_overlay_toast() {
    local severity="hint" message="Done" ttl="0"

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --severity|--style)
                severity="${2:-hint}"
                shift 2
                ;;
            --message)
                message="${2:-Done}"
                shift 2
                ;;
            --ttl)
                ttl="${2:-0}"
                shift 2
                ;;
            *)
                message="${message:+$message }$1"
                shift
                ;;
        esac
    done
    ui check-item "$severity" "$message" ""
    case "$ttl" in
        0|''|*[!0-9.]*)
            ;;
        *)
            ui_can_animate && sleep "$ttl"
            ;;
    esac
}

ui_overlay_popover() {
    local title="Details" content=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --title)
                title="${2:-Details}"
                shift 2
                ;;
            *)
                content="${content}${content:+
}$1"
                shift
                ;;
        esac
    done
    if [ -z "$content" ] && [ ! -t 0 ]; then
        content="$(cat)"
    fi
    ui panel --title "$title" --severity hint "$content"
}

ui_overlay_example() {
    ui overlay modal --title "Enable helper UI" --severity warning "Air will write UI state only after the helper is usable."
    ui overlay tooltip --target "NVM_DIR" --text "Path is resolved at runtime; no machine-specific Node bin is written."
    ui overlay toast --severity ok --message "Runtime generated"
    ui overlay popover --title "Command hint" 'Use `air ui example effects` to run motion examples.'
}

ui_overlay() {
    local command="${1:-help}"

    shift || true
    case "$command" in
        -h|--help|help) ui_overlay_help ;;
        modal|dialog) ui_overlay_modal "$@" ;;
        tooltip|hint) ui_overlay_tooltip "$@" ;;
        toast) ui_overlay_toast "$@" ;;
        popover) ui_overlay_popover "$@" ;;
        example) ui_overlay_example "$@" ;;
        *)
            ui check-item error "ui overlay" "Unknown overlay component: $command"
            return 1
            ;;
    esac
}

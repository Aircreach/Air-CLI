# Air native UI command surface.

_air_ui_command_help() {
    ui command-help <<'EOF'
# air ui

Air native UI is the product-facing output and interaction layer used by core commands and plugins.

Usage:
  air ui
  air ui status
  air ui components
  air ui example [component] [--static|-s]
  air ui preview
  air ui check
  air ui run <flow.toml>
  air ui enable --helper
  air ui disable --helper

Helper UI is optional. Basic Bash UI remains the default and is always the startup-safe fallback.
EOF
}

_air_ui_configured_mode() {
    ui_load_settings
    printf '%s\n' "${AIR_UI_MODE:-basic}"
}

air_ui_status() {
    ui kv "configured" "$(_air_ui_configured_mode)"
    ui kv "effective" "$(ui_effective_mode)"
    ui kv "settings" "$(ui_settings_path)"
    ui kv "helper" "$(ui_helper_path)"
    ui kv "helper file" "$(ui_helper_installed && printf installed || printf missing)"
    ui kv "helper usable" "$(ui_helper_available && printf yes || printf no)"
    ui kv "can build" "$(ui_helper_can_build && printf yes || printf no)"
    ui kv "plain" "$(ui_is_plain && printf yes || printf no)"
    ui kv "interactive" "$(ui_is_interactive && printf yes || printf no)"
    ui kv "non-interactive" "${AIR_NON_INTERACTIVE:-0}"
    ui kv "yes mode" "${AIR_YES:-0}"
}

air_ui_components() {
    {
        printf 'COMPONENT\tAPI\tPURPOSE\n'
        printf 'text\tui text\tInline markup: **bold**, //italic//, __underline__, ~~strike~~, [[muted]], ^^inverse^^, `code`, ==hint==, !!accent!!, {{pill}}\n'
        printf 'markdown\tui markdown\tLightweight Markdown rendering\n'
        printf 'panel\tui panel\tFramed multi-line content\n'
        printf 'layout\tui layout\tStack, grid, split, screen, wizard, rail, viewport, and TOML layout rendering\n'
        printf 'effects\tui effects\tExplicit frame-rendered text effects: shimmer, typewriter, wave, cursor, reveal, gradient, heatmap, highlight, morph, particle\n'
        printf 'overlay\tui overlay\tTerminal modal, tooltip/callout, toast, and popover patterns\n'
        printf 'example\tui example\tRun component examples; use `air ui example [component] [--static|-s]`\n'
        printf 'marker\tui marker\tStable status marker slots for done, current, pending, warning, and error states\n'
        printf 'badge\tui badge\tCompact colored label/pill with plain fallback\n'
        printf 'block\tui block\tSeverity block: done, warning, error, blocked, hint\n'
        printf 'check-item\tui check-item\tStandard check/preflight item\n'
        printf 'log\tui log\tStandard log/status message\n'
        printf 'flow\tui flow\tRun a caller-owned guided UI flow from TOML\n'
        printf 'input\tui input\tPrompt for a value\n'
        printf 'password\tui password\tPrompt for hidden input\n'
        printf 'confirm\tui confirm\tConfirm risky or warning-level actions\n'
        printf 'select\tui select\tChoose one value; options may be value, value<TAB>label, or value<TAB>label<TAB>hint\n'
        printf 'multiselect\tui multiselect\tChoose multiple values\n'
        printf 'table\tui table\tRender tab-separated data\n'
        printf 'kv\tui kv\tRender one key/value row\n'
        printf 'summary\tui summary\tRender a compact key/value summary\n'
        printf 'list\tui list\tRender list items\n'
        printf 'progress\tui progress\tMeasured progress; use `ui progress example` for the 0%% to 100%% story\n'
        printf 'spinner\tui spinner\tRun a command with loading state\n'
        printf 'task\tui task\tRun and summarize a named task\n'
        printf 'step\tui step\tRender a step result\n'
        printf 'code\tui code\tRender code/output text\n'
        printf 'hr\tui hr\tRender a horizontal rule\n'
    } | ui table
}

air_ui_example() {
    ui example "$@"
}

air_ui_preview() {
    local tmp_right

    ui title "Air UI Preview"
    printf '  '
    ui_badge "helper UI" hint
    printf ' '
    ui_badge "basic fallback" ok
    printf ' '
    ui_badge "plain safe" warning
    printf '\n'
    ui spacer
    ui block ok "OK block" "A completed operation with **important** context."
    ui block warning "Warning block" "A recoverable issue that needs confirmation."
    ui block error "Error block" "A command cannot continue until this is fixed."
    ui block blocked "Blocked block" "A safety check refused to write state."
    ui block hint "Hint block" "A non-critical suggestion for the next step."
    ui spacer
    ui panel --title "Panel" --severity hint 'Panels render larger paragraphs, `paths`, ==highlighted values==, !!accent text!!, [[muted text]], and {{pill text}} without requiring the helper.'
    ui spacer
    ui hr --label "text"
    ui text 'ANSI style: **bold**, //italic//, __underline__, ~~strike~~, [[muted]], ^^inverse^^, `code`, {{pill}}'
    ui check-item hint "font size" "Terminals cannot change font size per line; use spacing, block characters, and layout hierarchy instead."
    ui spacer
    ui hr --label "layout"
    tmp_right="$(mktemp)"
    {
        printf 'Check shell\n'
        printf 'Choose build path\n'
        printf 'Build helper\n'
        printf 'Preview\n'
    } > "$tmp_right"
    ui layout wizard \
        --current 3 \
        --total 4 \
        --kind task \
        --title "Build helper in Docker" \
        --message "This layout keeps the active step obvious while the right rail shows where you are in the whole flow." \
        --next "Preview" \
        --steps-file "$tmp_right"
    rm -f "$tmp_right"
    ui layout viewport --title "Build output" --lines 3 <<'EOF'
fetch golang:1.22
mount Air workspace
compile helper
write ~/.air/runtime/ui/air-ui
EOF
    ui spacer
    ui markdown <<'EOF'
## Markdown
- Supports **bold**, `code`, ==accent==, [done], [warn], [error]
> Plain mode removes decoration while keeping the structure readable.
EOF
    ui hr --label data
    ui kv "mode" "$(ui_effective_mode)"
    {
        printf 'NAME\tSTATUS\tNOTES\n'
        printf 'basic\tready\tBash fallback\n'
        printf 'helper\t%s\toptional air-ui helper\n' "$(ui_helper_available && printf usable || printf disabled)"
        printf 'plain\t%s\tNO_COLOR fallback\n' "$(ui_is_plain && printf enabled || printf disabled)"
    } | ui table
    ui list 'Plugin API stays `ui ...`' 'User entry stays `air ui ...`' "Helper UI never runs during shell startup"
    ui hr --label "overlay"
    ui overlay tooltip --target "AIR_HOME" --text "Explicit callout; terminal hover tooltip is not a native capability."
    ui overlay toast --severity ok --message "Settings saved"
    ui hr --label "input"
    ui check-item hint "input field" "Interactive input uses a prominent prompt, default-value pill, and a focused entry line."
    ui code 'ui input --prompt "Project name" --default Air'
    ui hr --label "selection"
    ui check-item hint "select menu" "Interactive menus show labels and hints, while scripts receive stable values."
    ui code 'ui select --style menu --option "docker-go<TAB>Build in Docker<TAB>Temporary Go container; no host Go install."'
    ui hr --label "loading"
    ui task --title "Loading sample" -- sleep 0.2
    ui hr --label "measured work"
    ui progress --label "download" --current 65 --total 100
    ui progress --label "segments" --bar block --spinner none --current 65 --total 100
    ui progress --label "transfer" --bar block --spinner braille --width 20 --current 100 --total 100
    ui hr --label "effects"
    ui check-item hint "frame renderer" 'Run `air ui example effects` to see shimmer/typewriter/wave/reveal examples.'
    ui effects shimmer --label "Parsing data" --width 16
    ui effects gradient --text "Air UI"
    ui effects heatmap --label "load" --values "1 2 4 6 8 10"
}

air_ui_check() {
    local status=0

    ui kv "configured" "$(_air_ui_configured_mode)"
    ui kv "effective" "$(ui_effective_mode)"
    ui check-item ok "basic UI" "Bash fallback components are loaded."

    if ui_is_plain; then
        ui check-item ok "plain fallback" "--plain or NO_COLOR is active; helper output is bypassed."
    elif terminal_supports_color; then
        ui check-item ok "color" "Terminal supports ANSI color."
    else
        ui check-item warning "color" "Color is unavailable; output remains readable."
    fi

    if ui_is_interactive; then
        ui check-item ok "interactive" "Prompts can be displayed."
    else
        ui check-item warning "interactive" "Prompts are disabled or stdin is not a TTY."
    fi

    if ui_helper_installed; then
        ui check-item ok "helper file" "$(ui_helper_path)"
    elif ui_helper_can_build; then
        ui check-item warning "helper file" "Missing, but Go is available for building."
    else
        ui check-item warning "helper file" "Missing and Go is not available; helper UI cannot be enabled here."
    fi

    if ui_helper_mode_enabled; then
        if ui_helper_available; then
            ui check-item ok "helper UI" "Enabled and usable."
        elif ui_is_plain || ! ui_is_interactive; then
            ui check-item warning "helper UI" "Enabled in settings but this context intentionally falls back to basic UI."
        else
            ui check-item warning "helper UI" "Enabled in settings but currently falling back to basic UI."
            status=1
        fi
    else
        ui check-item hint "helper UI" 'Disabled. Run `air ui enable --helper` to opt in.'
    fi

    return "$status"
}

air_ui_helper_flow_path() {
    printf '%s\n' "$(ui_path flows/helper-enable.toml)"
}

air_ui_enable() {
    local mode="${1:-}"

    case "$mode" in
        --helper)
            ui flow "$(air_ui_helper_flow_path)"
            ;;
        -h|--help|'')
            ui command-help <<'EOF'
# air ui enable

Usage:
  air ui enable --helper

Runs the helper UI flow. It checks the optional `air-ui` helper, builds it when possible, previews the result, and writes Air UI state only after the helper path is usable.
EOF
            ;;
        *)
            ui check-item error "air ui enable" "Unknown option: $mode"
            return 1
            ;;
    esac
}

air_ui_disable() {
    local mode="${1:-}"

    case "$mode" in
        --helper|'')
            ui_disable_helper_state
            AIR_UI_MODE=basic
            export AIR_UI_MODE
            ui check-item ok "helper UI" "Disabled. Basic Bash UI is active."
            ;;
        -h|--help)
            ui command-help <<'EOF'
# air ui disable

Usage:
  air ui disable --helper
EOF
            ;;
        *)
            ui check-item error "air ui disable" "Unknown option: $mode"
            return 1
            ;;
    esac
}

air_ui_run() {
    local file="${1:-}"

    [ -n "$file" ] || {
        ui check-item error "air ui run" "Missing flow TOML path."
        return 1
    }
    ui flow "$file"
}

air_ui() {
    local command="${1:-status}"

    case "$command" in
        -h|--help|help)
            _air_ui_command_help
            ;;
        ''|status|helper-status)
            air_ui_status
            ;;
        components)
            air_ui_components
            ;;
        example)
            shift
            air_ui_example "$@"
            ;;
        preview)
            shift
            air_ui_preview "$@"
            ;;
        check)
            air_ui_check
            ;;
        run)
            shift
            air_ui_run "$@"
            ;;
        enable)
            shift
            air_ui_enable "$@"
            ;;
        disable)
            shift
            air_ui_disable "$@"
            ;;
        *)
            ui check-item error "air ui" "Unknown command: $command"
            ui check-item hint "usage" 'Run `air ui --help`.'
            return 1
            ;;
    esac
}

# Air UI text, markdown, panels, and terminal styling.

ui_supports_color() {
    ! ui_is_plain && terminal_supports_color
}

ui_can_animate() {
    ! ui_is_plain && ui_is_interactive && terminal_can_animate
}

ui_terminal_width() {
    terminal_width
}

ui_color() {
    local code="$1"

    shift
    if ui_supports_color; then
        printf '\033[%sm%s\033[0m' "$code" "$*"
    else
        printf '%s' "$*"
    fi
}

ui_sgr() {
    ui_supports_color && printf '\033[%sm' "$1"
}

ui_reset() {
    ui_supports_color && printf '\033[0m'
}

ui_icon_enabled() {
    case "${AIR_UI_SYMBOL_STYLE:-auto}" in
        ascii|text|plain) return 1 ;;
        unicode|icon) ! ui_is_plain ;;
        auto|*) ! ui_is_plain && terminal_supports_color ;;
    esac
}

ui_icon() {
    local name="$1" fallback="" value

    case "$name" in
        ok) fallback="$AIR_UI_SYMBOL_OK"; value="$AIR_UI_ICON_OK" ;;
        warning|warn) fallback="$AIR_UI_SYMBOL_WARNING"; value="$AIR_UI_ICON_WARNING" ;;
        error) fallback="$AIR_UI_SYMBOL_ERROR"; value="$AIR_UI_ICON_ERROR" ;;
        blocked) fallback="$AIR_UI_SYMBOL_BLOCKED"; value="$AIR_UI_ICON_BLOCKED" ;;
        hint|info) fallback="$AIR_UI_SYMBOL_HINT"; value="$AIR_UI_ICON_HINT" ;;
        current) fallback=">"; value="$AIR_UI_ICON_CURRENT" ;;
        done) fallback="ok"; value="$AIR_UI_ICON_DONE" ;;
        pending) fallback="-"; value="$AIR_UI_ICON_PENDING" ;;
        select) fallback=">"; value="$AIR_UI_ICON_SELECT" ;;
        panel) fallback="|"; value="$AIR_UI_ICON_PANEL" ;;
        input) fallback="?"; value="$AIR_UI_ICON_INPUT" ;;
        loading) fallback="."; value="$AIR_UI_ICON_LOADING" ;;
        *) fallback="$name"; value="$name" ;;
    esac

    if ui_icon_enabled; then
        printf '%s\n' "$value"
    else
        printf '%s\n' "$fallback"
    fi
}

ui_severity_color() {
    case "$1" in
        ok|success|done) printf '%s\n' "$AIR_UI_COLOR_OK" ;;
        warning|warn) printf '%s\n' "$AIR_UI_COLOR_WARNING" ;;
        error|failed) printf '%s\n' "$AIR_UI_COLOR_ERROR" ;;
        blocked) printf '%s\n' "$AIR_UI_COLOR_BLOCKED" ;;
        hint|info|*) printf '%s\n' "$AIR_UI_COLOR_HINT" ;;
    esac
}

ui_badge() {
    local text="$1" severity="${2:-hint}" bg

    if [ "$text" = "example" ] && [ "$#" -eq 1 ]; then
        ui title "Badge Example"
        printf '  '
        ui_badge "helper UI" hint
        printf ' '
        ui_badge "ready" ok
        printf ' '
        ui_badge "warning" warning
        printf ' '
        ui_badge "blocked" blocked
        printf '\n'
        return 0
    fi

    bg="$AIR_UI_COLOR_PILL_BG"
    if ui_supports_color; then
        case "$severity" in
            ok|success|done) bg="42" ;;
            warning|warn) bg="43" ;;
            error|failed|blocked) bg="41" ;;
            *) bg="$AIR_UI_COLOR_PILL_BG" ;;
        esac
        printf '\033[%s;%sm %s \033[0m' "$bg" "$AIR_UI_COLOR_PILL_FG" "$text"
    else
        printf '[%s]' "$text"
    fi
}

ui_risk_default() {
    case "${1:-medium}" in
        low) printf 'yes\n' ;;
        medium|high|destructive|*) printf 'no\n' ;;
    esac
}

ui_help() {
    cat <<'EOF'
ui - Air internal component API

Usage:
  ui <component> [options]

Components:
  text          Render inline markup: **bold**, //italic//, __underline__, ~~strike~~, [[muted]], ^^inverse^^, `code`, ==hint==, !!accent!!, {{pill}}
  markdown      Render lightweight Markdown from args or stdin
  panel         Render a bordered message panel
  layout        Render split layouts, wizard headers, viewports, and step rails
  effects       Render explicit time-based text effects
  overlay       Render modal, tooltip, toast, and popover patterns
  badge|pill    Render a compact colored label
  block         Render a severity block: done, warning, error, blocked, hint
  check-item    Render a standard check/workflow item
  log           Render a standard log line/block
  input         Prompt for a value, with non-interactive fallback
  password      Prompt for a hidden value
  select        Prompt for one value; options may include label and hint fields
  multiselect   Prompt for comma-separated values
  confirm       Ask for yes/no confirmation
  table         Render tab-separated rows
  kv            Render a key/value row
  summary       Render a compact key/value summary
  list          Render list items
  progress      Render measured work progress, not ordinary flow navigation
  spinner       Run a command with a loading indicator
  task          Run a command as a named task
  step          Render a step state
  example       Run component examples: ui example [component] [--static|-s]
  marker        Render stable marker slots for done/current/pending states
  code          Render code-like text
  hr            Render a horizontal rule

Context:
  AIR_PLAIN=1 or --plain disables decoration.
  AIR_NON_INTERACTIVE=1 or --non-interactive forbids prompts.
  AIR_YES=1 or --yes accepts confirmations.
  Helper UI is configured with air ui enable --helper.
EOF
}

ui_helper_status() {
    ui kv "configured" "${AIR_UI_MODE:-basic}"
    ui kv "effective" "$(ui_effective_mode)"
    ui kv "helper" "$(ui_helper_path)"
    ui kv "helper file" "$(ui_helper_installed && printf installed || printf missing)"
    ui kv "helper usable" "$(ui_helper_available && printf yes || printf no)"
    ui kv "can build" "$(ui_helper_can_build && printf yes || printf no)"
}

ui_style_value() {
    local value="$1"

    case "$value" in
        enabled|ready|success|ok|usable|installed|passed|yes|true|helper)
            ui_color "$AIR_UI_COLOR_OK" "$value"
            ;;
        disabled|missing|medium|warn|warning|stale|partial|skipped|basic|plain|false|no)
            ui_color "$AIR_UI_COLOR_WARNING" "$value"
            ;;
        high|destructive|error|failed|blocked|unusable|denied)
            ui_color "$AIR_UI_COLOR_ERROR" "$value"
            ;;
        starship|focus|dense|spacious)
            ui_color "$AIR_UI_COLOR_HINT" "$value"
            ;;
        *)
            printf '%s' "$value"
            ;;
    esac
}

ui_status_token_text() {
    local state="$1" style="${2:-icon}"

    case "$style" in
        text)
            ui marker "$state" --style text
            ;;
        icon|*)
            ui marker "$state" --style bracket
            ;;
    esac
}

ui_format_inline() {
    local text="$*"
    local reset bold italic underline strike inverse code done warn err hint muted accent pill_open pill_close
    local status_style="${AIR_UI_STATUS_STYLE:-icon}"

    if ! ui_supports_color; then
        printf '%s\n' "$text" | sed -E \
            -e 's/\*\*([^*]+)\*\*/\1/g' \
            -e 's#//([^/]+)//#\1#g' \
            -e 's/__([^_]+)__/\1/g' \
            -e 's/`([^`]+)`/\1/g' \
            -e 's/==([^=]+)==/\1/g' \
            -e 's/!!([^!]+)!!/\1/g' \
            -e 's/\[\[([^]]+)\]\]/\1/g' \
            -e 's/~~([^~]+)~~/\1/g' \
            -e 's/\^\^([^^]+)\^\^/\1/g' \
            -e 's/\{\{([^}]+)\}\}/[\1]/g' \
            -e 's/\[done\]/DONE/g' \
            -e 's/\[warn\]/WARN/g' \
            -e 's/\[error\]/ERROR/g'
        return 0
    fi

    reset="$(printf '\033[0m')"
    bold="$(printf '\033[%sm' "$AIR_UI_COLOR_BOLD")"
    italic="$(printf '\033[%sm' "$AIR_UI_COLOR_ITALIC")"
    underline="$(printf '\033[%sm' "$AIR_UI_COLOR_UNDERLINE")"
    strike="$(printf '\033[%sm' "$AIR_UI_COLOR_STRIKE")"
    inverse="$(printf '\033[%sm' "$AIR_UI_COLOR_INVERSE")"
    code="$(printf '\033[%sm' "$AIR_UI_COLOR_CODE")"
    done="$(ui_status_token_text done "$status_style")"
    warn="$(ui_status_token_text warn "$status_style")"
    err="$(ui_status_token_text error "$status_style")"
    hint="$(printf '\033[%sm' "$AIR_UI_COLOR_HINT")"
    muted="$(printf '\033[%sm' "$AIR_UI_COLOR_MUTED")"
    accent="$(printf '\033[%sm' "$AIR_UI_COLOR_ACCENT")"
    pill_open="$(printf '\033[%s;%sm ' "$AIR_UI_COLOR_PILL_BG" "$AIR_UI_COLOR_PILL_FG")"
    pill_close="$(printf ' %s' "$reset")"

    printf '%s\n' "$text" | sed -E \
        -e "s/\*\*([^*]+)\*\*/${bold}\1${reset}/g" \
        -e "s#//([^/]+)//#${italic}\1${reset}#g" \
        -e "s/__([^_]+)__/${underline}\1${reset}/g" \
        -e "s/==([^=]+)==/${hint}\1${reset}/g" \
        -e "s/\\[\\[([^]]+)\\]\\]/${muted}\1${reset}/g" \
        -e "s/~~([^~]+)~~/${strike}\1${reset}/g" \
        -e "s/\\^\\^([^^]+)\\^\\^/${inverse}\1${reset}/g" \
        -e "s/!!([^!]+)!!/${accent}\1${reset}/g" \
        -e "s/\\{\\{([^}]+)\\}\\}/${pill_open}\1${pill_close}/g" \
        -e "s/\`([^\`]+)\`/${code}\1${reset}/g" \
        -e "s/\\[done\\]/${done}/g" \
        -e "s/\\[warn\\]/${warn}/g" \
        -e "s/\\[error\\]/${err}/g"
}

ui_text() {
    local status_style=""

    if [ "${1:-}" = "example" ]; then
        ui title "Text Example"
        printf '  '
        ui_format_inline '**Bold** //Italic// __Underline__ ~~Strike~~ [[Muted]] ^^Inverse^^ `code` ==hint== !!accent!! {{pill}} [done] [warn] [error]'
        printf '  '
        AIR_UI_STATUS_STYLE=text ui_format_inline 'Text status: [done] [warn] [error]'
        ui check-item hint "font size" "Terminal font size is emulator-level; use glyph, style, and layout hierarchy instead."
        ui check-item hint "frame effects" 'Motion is explicit: call `ui effects ...`; plain and non-TTY output render stable frames.'
        return 0
    fi
    if [ "${1:-}" = "--status-style" ]; then
        status_style="${2:-icon}"
        shift 2
    fi
    if [ "$#" -gt 0 ]; then
        if [ -n "$status_style" ]; then
            AIR_UI_STATUS_STYLE="$status_style" ui_format_inline "$*"
        else
            ui_format_inline "$*"
        fi
    elif [ ! -t 0 ]; then
        while IFS= read -r line; do
            ui_format_inline "$line"
        done
    fi
}

ui_title() {
    local text="$*"

    ui_color "$AIR_UI_COLOR_TITLE" "$text"
    printf '\n'
}

ui_spacer() {
    local count="${1:-1}"

    case "$count" in
        ''|*[!0-9]*) count=1 ;;
    esac
    while [ "$count" -gt 0 ]; do
        printf '\n'
        count=$((count - 1))
    done
}

ui_hr() {
    local label="" width char line left right

    if [ "${1:-}" = "example" ]; then
        ui title "Rule Example"
        ui_hr --label "section"
        ui_hr --char "=" --label "strong boundary"
        return 0
    fi

    width="$(ui_terminal_width)"
    char="-"
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --label)
                label="${2:-}"
                shift 2
                ;;
            --char)
                char="${2:--}"
                shift 2
                ;;
            *)
                label="${label:-$1}"
                shift
                ;;
        esac
    done

    width=$((width - 4))
    [ "$width" -lt 12 ] && width=12
    if [ -n "$label" ]; then
        left=$(((width - ${#label} - 2) / 2))
        right=$((width - ${#label} - 2 - left))
        line="$(printf '%*s' "$left" '' | tr ' ' "$char") $label $(printf '%*s' "$right" '' | tr ' ' "$char")"
    else
        line="$(printf '%*s' "$width" '' | tr ' ' "$char")"
    fi
    printf '  '
    ui_color "$AIR_UI_COLOR_MUTED" "$line"
    printf '\n'
}

ui_code() {
    local title="" language="" content="" width color icon content_width line rendered

    if [ "${1:-}" = "example" ]; then
        ui title "Code Example"
        ui_code --title "bash" --language bash 'AIR_HOME="${AIR_HOME:-$HOME/.local/share/air}"
ui progress --label Download --current 65 --total 100'
        return 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --title)
                title="${2:-}"
                shift 2
                ;;
            --language|--lang)
                language="${2:-}"
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
    [ -n "$content" ] || return 0

    if ! ui_icon_enabled; then
        if [ -n "$title$language" ]; then
            if [ -n "$language" ]; then
                printf '  ```%s\n' "$language"
            else
                printf '  ```%s\n' "$title"
            fi
        fi
        printf '%s\n' "$content" | while IFS= read -r line || [ -n "$line" ]; do
            printf '  '
            ui_color "$AIR_UI_COLOR_CODE" "$line"
            printf '\n'
        done
        [ -n "$title$language" ] && printf '  ```\n'
        return 0
    fi

    width="$(ui_terminal_width)"
    width=$((width - 4))
    [ "$width" -lt 24 ] && width=24
    content_width=$((width - 6))
    color="$AIR_UI_COLOR_PANEL"
    icon="$(ui_icon panel)"
    printf '  '
    ui_color "$color" "╭─"
    if [ -n "$title" ] || [ -n "$language" ]; then
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "${title:-code}"
        [ -n "$language" ] && {
            printf ' '
            ui_badge "$language" hint
        }
    fi
    printf '\n'
    printf '%s\n' "$content" | fold -s -w "$content_width" | while IFS= read -r line || [ -n "$line" ]; do
        rendered="$(ui_format_inline "\`$line\`")"
        printf '  '
        ui_color "$color" "$icon"
        printf '  '
        printf '%s\n' "$rendered"
    done
    printf '  '
    ui_color "$color" "╰─"
    printf '\n'
}

ui_markdown_render_code_block() {
    local language="$1" content="$2"

    ui_code --language "$language" "$content"
}

ui_markdown() {
    local input="" line in_code=0 heading code_buffer="" code_language=""

    if [ "${1:-}" = "example" ]; then
        ui title "Markdown Example"
        ui_markdown <<'EOF'
## Terminal copy
- Supports **bold**, `code`, ==hint==, !!accent!!, and status tokens [done] [warn] [error]
```bash
air ui example progress
```
> The fallback renderer keeps the same structure without decoration.
EOF
        return 0
    fi

    if ui_helper_available; then
        if [ "$#" -gt 0 ]; then
            printf '%s\n' "$*" | ui_helper markdown
        else
            ui_helper markdown
        fi
        return "$?"
    fi

    if [ "$#" -gt 0 ]; then
        input="$*"
    elif [ ! -t 0 ]; then
        input="$(cat)"
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            '```'*)
                if [ "$in_code" = "1" ]; then
                    in_code=0
                    ui_markdown_render_code_block "$code_language" "$code_buffer"
                    code_buffer=""
                    code_language=""
                else
                    in_code=1
                    code_language="${line#\`\`\`}"
                    code_buffer=""
                fi
                continue
                ;;
        esac

        if [ "$in_code" = "1" ]; then
            code_buffer="${code_buffer}${code_buffer:+
}$line"
            continue
        fi

        case "$line" in
            '# '*)
                heading="${line#\# }"
                ui_title "$heading"
                ;;
            '## '*)
                heading="${line#\#\# }"
                printf '  '
                ui_color "$AIR_UI_COLOR_HEADER" "$heading"
                printf '\n'
                ;;
            '- '*)
                printf '  - '
                ui_text "${line#- }"
                ;;
            '> '*)
                printf '  '
                ui_color "$AIR_UI_COLOR_MUTED" "${line#> }"
                printf '\n'
                ;;
            '')
                printf '\n'
                ;;
            *)
                printf '  '
                ui_text "$line"
                ;;
        esac
    done <<EOF
$input
EOF
    [ "$in_code" = "1" ] && ui_markdown_render_code_block "$code_language" "$code_buffer"
}

ui_panel() {
    local title="" severity="hint" content="" width color rendered content_width icon top bottom

    if [ "${1:-}" = "example" ]; then
        ui title "Panel Example"
        ui_panel --title "Commit boundary" --severity warning "Panels are for previews, warnings, summaries, or commit points. Avoid boxing every paragraph."
        return 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --title)
                title="${2:-}"
                shift 2
                ;;
            --severity|--style)
                severity="${2:-hint}"
                shift 2
                ;;
            --width)
                width="${2:-}"
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

    if ui_helper_available; then
        printf '%s\n' "$content" | ui_helper panel --title "$title" --severity "$severity"
        return "$?"
    fi

    [ -n "$width" ] || width="$(ui_terminal_width)"
    width=$((width - 4))
    [ "$width" -lt 20 ] && width=20
    content_width=$((width - 6))
    [ "$content_width" -lt 20 ] && content_width=20
    color="$(ui_block_color "$severity" 2>/dev/null || printf '%s' "$AIR_UI_COLOR_PANEL")"
    icon="$(ui_icon panel)"
    if ui_icon_enabled; then
        top="╭─"
        bottom="╰─"
    else
        top="+--"
        bottom="+--"
    fi

    printf '  '
    ui_color "$color" "$top"
    if [ -n "$title" ]; then
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "$title"
    fi
    printf '\n'
    printf '%s\n' "$content" | fold -s -w "$content_width" | while IFS= read -r line || [ -n "$line" ]; do
        rendered="$(ui_format_inline "$line")"
        printf '  '
        ui_color "$color" "$icon"
        printf '  '
        printf '%s' "$rendered"
        printf '\n'
    done
    printf '  '
    ui_color "$color" "$bottom"
    printf '\n'
}

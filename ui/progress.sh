# Air UI progress components.

ui_step() {
    local state="${1:-hint}" title="${2:-}" message="${3:-}"

    case "$state" in
        ok|success|done) ui block ok "$title" "$message" ;;
        warn|warning) ui block warning "$title" "$message" ;;
        error|failed) ui block error "$title" "$message" ;;
        blocked) ui block blocked "$title" "$message" ;;
        running|pending|info|hint|*) ui block hint "$title" "$message" ;;
    esac
}

ui_progress_default() {
    case "$1" in
        style) printf '%s\n' 'bar' ;;
        spinner) printf '%s\n' 'braille' ;;
        width) printf '%s\n' '20' ;;
        step) printf '%s\n' '5' ;;
        delay) printf '%s\n' '0.04' ;;
        bar.fill) printf '%s\n' '█' ;;
        bar.empty) printf '%s\n' '-' ;;
        blocks.fill) printf '%s\n' '▰' ;;
        blocks.empty) printf '%s\n' '▱' ;;
        dots.fill) printf '%s\n' '●' ;;
        dots.empty) printf '%s\n' '·' ;;
        braille.frames) printf '%s\n' '⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏' ;;
        line.frames) printf '%s\n' '- \ | /' ;;
        *) return 1 ;;
    esac
}

ui_progress_help() {
    ui command-help <<'EOF'
# ui progress

Render measured work progress.

Usage:
  ui progress --label <text> --current <n> --total <n> [options]
  ui progress example [options]

Options:
  --bar block|ascii|compact
  --style bar|blocks|dots
  --spinner braille|line|none
  --width <cells>
  --fill <char>
  --empty <char>
  --transient

Example story options:
  --delay <seconds>
  --step <percent>

Use component parameters for local styling. Theme/settings control broad UI
tokens such as color, mode, and density; they should not grow per-component
environment-variable sprawl.
EOF
}

ui_progress_example() {
    local style="bar" spinner="braille" width="" label="transfer" delay step current fill_char="" empty_char=""
    local fill_given=0 empty_given=0
    local -a progress_args
    local cancelled=0

    delay="$(ui_progress_default delay)"
    step="$(ui_progress_default step)"
    trap 'cancelled=1' INT
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --style|--bar)
                style="${2:-bar}"
                shift 2
                ;;
            --spinner)
                spinner="${2:-braille}"
                shift 2
                ;;
            --width)
                width="${2:-}"
                shift 2
                ;;
            --label)
                label="${2:-transfer}"
                shift 2
                ;;
            --delay)
                delay="${2:-$(ui_progress_default delay)}"
                shift 2
                ;;
            --step)
                step="${2:-$(ui_progress_default step)}"
                shift 2
                ;;
            --fill|--filled)
                fill_char="${2:-}"
                fill_given=1
                shift 2
                ;;
            --empty)
                empty_char="${2:-}"
                empty_given=1
                shift 2
                ;;
            --*)
                ui check-item error "ui progress example" "Unknown option: $1"
                return 1
                ;;
            *)
                label="${1:-$label}"
                shift
                ;;
        esac
    done

    case "$step" in ''|*[!0-9]*) step="$(ui_progress_default step)" ;; esac
    [ "$step" -le 0 ] && step="$(ui_progress_default step)"
    current=0
    while [ "$current" -lt 100 ]; do
        [ "$cancelled" = "1" ] && break
        progress_args=(--label "$label" --style "$style" --spinner "$spinner" --current "$current" --total 100 --transient)
        [ -n "$width" ] && progress_args+=(--width "$width")
        [ "$fill_given" = "1" ] && progress_args+=(--fill "$fill_char")
        [ "$empty_given" = "1" ] && progress_args+=(--empty "$empty_char")
        ui_progress "${progress_args[@]}"
        sleep "$delay"
        current=$((current + step))
    done
    trap - INT
    if [ "$cancelled" = "1" ]; then
        printf '\n'
        ui check-item warning "progress example" "Cancelled at ${current}%."
        return 130
    fi
    progress_args=(--label "$label" --style "$style" --spinner "$spinner" --current 100 --total 100 --transient)
    [ -n "$width" ] && progress_args+=(--width "$width")
    [ "$fill_given" = "1" ] && progress_args+=(--fill "$fill_char")
    [ "$empty_given" = "1" ] && progress_args+=(--empty "$empty_char")
    ui_progress "${progress_args[@]}"
}

ui_progress() {
    local current=0 total=100 label="" width filled empty percent bar transient=0 fill_char empty_char
    local style spinner spinner_frame="" frames frame_count color percent_color done=0
    local fill_given=0 empty_given=0

    style="$(ui_progress_default style)"
    spinner="$(ui_progress_default spinner)"
    width="$(ui_progress_default width)"

    case "${1:-}" in
        example)
            shift
            ui_progress_example "$@"
            return "$?"
            ;;
    esac

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                ui_progress_help
                return 0
                ;;
            --current)
                current="${2:-0}"
                shift 2
                ;;
            --total)
                total="${2:-100}"
                shift 2
                ;;
            --label)
                label="${2:-}"
                shift 2
                ;;
            --width)
                width="${2:-$(ui_progress_default width)}"
                shift 2
                ;;
            --style|--bar)
                style="${2:-bar}"
                shift 2
                ;;
            --spinner)
                spinner="${2:-braille}"
                shift 2
                ;;
            --fill|--filled)
                fill_char="${2:-}"
                fill_given=1
                shift 2
                ;;
            --empty)
                empty_char="${2:-}"
                empty_given=1
                shift 2
                ;;
            --transient)
                transient=1
                shift
                ;;
            --*)
                ui check-item error "ui progress" "Unknown option: $1"
                return 1
                ;;
            *)
                label="${label:-$1}"
                shift
                ;;
        esac
    done

    case "$current" in ''|*[!0-9]*) current=0 ;; esac
    case "$total" in ''|*[!0-9]*) total=100 ;; esac
    case "$width" in ''|*[!0-9]*) width="$(ui_progress_default width)" ;; esac
    [ "$width" -le 0 ] && width="$(ui_progress_default width)"
    [ "$total" -le 0 ] && total=1
    [ "$current" -lt 0 ] && current=0
    [ "$current" -gt "$total" ] && current="$total"

    percent=$((current * 100 / total))
    [ "$percent" -ge 100 ] && done=1
    filled=$((width * current / total))
    empty=$((width - filled))
    case "$style" in
        block|blocks|squares)
            style="blocks"
            [ -n "$fill_char" ] || fill_char="$(ui_progress_default blocks.fill)"
            [ -n "$empty_char" ] || empty_char="$(ui_progress_default blocks.empty)"
            ;;
        compact|dots|dot)
            style="dots"
            [ -n "$fill_char" ] || fill_char="$(ui_progress_default dots.fill)"
            [ -n "$empty_char" ] || empty_char="$(ui_progress_default dots.empty)"
            ;;
        bar|bracket|*)
            style="bar"
            [ -n "$fill_char" ] || fill_char="$(ui_progress_default bar.fill)"
            [ -n "$empty_char" ] || empty_char="$(ui_progress_default bar.empty)"
            ;;
    esac
    if ! ui_supports_color; then
        case "$style" in
            dots)
                [ "$fill_given" = "1" ] || fill_char="o"
                [ "$empty_given" = "1" ] || empty_char="."
                ;;
            blocks)
                [ "$fill_given" = "1" ] || fill_char="#"
                [ "$empty_given" = "1" ] || empty_char="-"
                ;;
            *)
                [ "$fill_given" = "1" ] || fill_char="#"
                [ "$empty_given" = "1" ] || empty_char="-"
                ;;
        esac
    fi
    bar=""
    while [ "$filled" -gt 0 ]; do
        bar="${bar}${fill_char}"
        filled=$((filled - 1))
    done
    while [ "$empty" -gt 0 ]; do
        bar="${bar}${empty_char}"
        empty=$((empty - 1))
    done
    [ "$style" = "bar" ] && bar="[$bar]"
    case "$spinner" in
        none|off|false|0)
            spinner_frame=""
            ;;
        line|ascii)
            frames="$(ui_progress_default line.frames)"
            frame_count="$(printf '%s\n' $frames | wc -l | awk '{print $1}')"
            [ "$frame_count" -gt 0 ] 2>/dev/null || frame_count=1
            spinner_frame="$(printf '%s\n' $frames | sed -n "$((percent % frame_count + 1))p")"
            [ -n "$spinner_frame" ] || spinner_frame="-"
            ;;
        braille|auto|*)
            frames="$(ui_progress_default braille.frames)"
            frame_count="$(printf '%s\n' $frames | wc -l | awk '{print $1}')"
            [ "$frame_count" -gt 0 ] 2>/dev/null || frame_count=1
            spinner_frame="$(printf '%s\n' $frames | sed -n "$((percent % frame_count + 1))p")"
            [ -n "$spinner_frame" ] || spinner_frame="."
            ! ui_supports_color && spinner_frame="."
            ;;
    esac
    [ "$done" = "1" ] && spinner_frame="$(ui marker done --style bracket)"
    if [ "$done" = "1" ]; then
        color="$AIR_UI_COLOR_MUTED"
        percent_color="$AIR_UI_COLOR_MUTED"
    else
        color="$AIR_UI_COLOR_HINT"
        percent_color="$AIR_UI_COLOR_MUTED"
    fi

    if [ "$transient" = "1" ] && ui_can_animate; then
        printf '\r  '
    else
        printf '  '
    fi
    [ -n "$spinner_frame" ] && {
        if [ "$done" = "1" ]; then
            printf '%s' "$spinner_frame"
        else
            ui_color "$color" "$spinner_frame"
        fi
        printf ' '
    }
    [ -n "$label" ] && {
        if [ "$done" = "1" ]; then
            ui_color "$AIR_UI_COLOR_MUTED" "$label"
        else
            ui_badge "$label" hint
        fi
        printf ' '
    }
    ui_color "$color" "$bar"
    printf ' '
    ui_color "$percent_color" "$percent%"
    if [ "$transient" = "1" ] && ui_can_animate && [ "$current" -lt "$total" ]; then
        :
    else
        printf '\n'
    fi
}

ui_spinner() {
    local title="Working" capture=0 transient=1 command_started=0
    local pid status frame frames frame_count index tmp

    if [ "${1:-}" = "example" ]; then
        ui_spinner --title "Resolving project" -- sleep 0.25
        return "$?"
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --title|--label)
                title="${2:-Working}"
                shift 2
                ;;
            --capture)
                capture=1
                shift
                ;;
            --no-transient)
                transient=0
                shift
                ;;
            --)
                shift
                command_started=1
                break
                ;;
            *)
                break
                ;;
        esac
    done

    if [ "$#" -eq 0 ]; then
        ui block hint "$title" ""
        return 0
    fi

    if ! ui_can_animate; then
        printf '  '
        ui_color "$AIR_UI_COLOR_HINT" "$(ui_icon loading)"
        printf ' '
        ui_badge "loading" hint
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "$title"
        printf '\n'
        "$@"
        return "$?"
    fi

    frames="${AIR_UI_SPINNER_FRAMES:-- \\ | /}"
    frame_count="$(printf '%s\n' $frames | wc -l | awk '{print $1}')"
    [ "$frame_count" -gt 0 ] 2>/dev/null || frame_count=4

    tmp=""
    if [ "$capture" = "1" ]; then
        tmp="$(mktemp)"
        "$@" >"$tmp" 2>&1 &
    else
        "$@" &
    fi
    pid="$!"
    index=1
    status=0
    while kill -0 "$pid" >/dev/null 2>&1; do
        frame="$(printf '%s\n' $frames | sed -n "${index}p")"
        [ -n "$frame" ] || frame="-"
        printf '\r  ' >&2
        ui_color "$AIR_UI_COLOR_HINT" "$frame" >&2
        printf ' ' >&2
        ui_badge "loading" hint >&2
        printf ' ' >&2
        ui_color "$AIR_UI_COLOR_TITLE" "$title" >&2
        sleep 0.12
        index=$((index + 1))
        [ "$index" -gt "$frame_count" ] && index=1
    done
    wait "$pid" || status="$?"

    if [ "$transient" = "1" ]; then
        printf '\r%*s\r' "$((${#title} + 6))" '' >&2
    else
        printf '\n' >&2
    fi

    if [ "$capture" = "1" ] && [ -n "$tmp" ]; then
        if [ "$status" != "0" ] && [ -s "$tmp" ]; then
            cat "$tmp" >&2
        fi
        rm -f "$tmp"
    fi
    return "$status"
}

ui_task() {
    local title="Task" status

    if [ "${1:-}" = "example" ]; then
        ui_task --title "Generate runtime" -- sleep 0.2
        return "$?"
    fi

    if [ "${1:-}" = "--title" ]; then
        title="${2:-Task}"
        shift 2
    elif [ "$#" -gt 0 ]; then
        title="$1"
        shift
    fi
    [ "${1:-}" = "--" ] && shift

    if [ "$#" -eq 0 ]; then
        ui step hint "$title"
        return 0
    fi

    status=0
    ui spinner --title "$title" -- "$@" || status="$?"
    if [ "$status" = "0" ]; then
        ui step ok "$title" "done"
        return 0
    fi
    ui step error "$title" "failed with status $status"
    return "$status"
}

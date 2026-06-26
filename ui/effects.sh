# Air UI time-based text effects. Effects are explicit CLI output only.

ui_effects_help() {
    ui command-help <<'EOF'
# ui effects

Time-based terminal effects for explicit CLI commands.

Usage:
  ui effects <effect> [options]

Effects:
  shimmer       Sweep a highlight across a fixed-width rail
  typewriter    Print text one character at a time
  wave          Highlight one character at a time
  cursor        Render a blinking cursor sample
  blink         Alias for cursor
  reveal        Reveal text from a mask
  gradient      Color characters across a small palette
  heatmap       Render intensity blocks
  highlight     Highlight a matching phrase in context
  morph         Morph one short label into another
  particle      Reveal text through lightweight character particles
  ghost         Contract trailing dots
  example       Run the component story

Notes:
  Effects never run during shell startup. In --plain, NO_COLOR, non-TTY, or
  TERM=dumb contexts they render a stable final frame instead of animating.
EOF
}

ui_effects_sleep() {
    sleep "${1:-0.05}"
}

ui_effects_repeat() {
    local char="$1" count="$2" out=""

    case "$count" in ''|*[!0-9]*) count=0 ;; esac
    while [ "$count" -gt 0 ]; do
        out="${out}${char}"
        count=$((count - 1))
    done
    printf '%s' "$out"
}

ui_effects_frame_prefix() {
    if ui_can_animate; then
        printf '\r  '
    else
        printf '  '
    fi
}

ui_effects_frame_done() {
    if ui_can_animate; then
        printf '\n'
    fi
}

ui_effects_shimmer() {
    local label="Loading" width=18 frames=24 delay="0.04" fill="░" highlight="█"
    local i pos rail j

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --label)
                label="${2:-Loading}"
                shift 2
                ;;
            --width)
                width="${2:-18}"
                shift 2
                ;;
            --frames)
                frames="${2:-24}"
                shift 2
                ;;
            --delay)
                delay="${2:-0.04}"
                shift 2
                ;;
            --fill)
                fill="${2:-░}"
                shift 2
                ;;
            --highlight)
                highlight="${2:-█}"
                shift 2
                ;;
            *)
                label="${label:-$1}"
                shift
                ;;
        esac
    done
    case "$width" in ''|*[!0-9]*) width=18 ;; esac
    case "$frames" in ''|*[!0-9]*) frames=24 ;; esac
    if ! ui_can_animate; then
        ui progress --label "$label" --style blocks --spinner none --current 65 --total 100 --width "$width"
        return 0
    fi
    i=0
    while [ "$i" -lt "$frames" ]; do
        pos=$((i % width))
        rail=""
        j=0
        while [ "$j" -lt "$width" ]; do
            if [ "$j" -eq "$pos" ]; then
                rail="${rail}${highlight}"
            else
                rail="${rail}${fill}"
            fi
            j=$((j + 1))
        done
        ui_effects_frame_prefix
        ui_color "$AIR_UI_COLOR_HINT" "⠋"
        printf ' '
        ui_badge "$label" hint
        printf ' '
        ui_color "$AIR_UI_COLOR_MUTED" "[$rail]"
        ui_effects_sleep "$delay"
        i=$((i + 1))
    done
    ui_effects_frame_prefix
    ui marker done --style bracket
    printf ' '
    ui_color "$AIR_UI_COLOR_MUTED" "$label"
    printf ' '
    ui_color "$AIR_UI_COLOR_MUTED" "[$(ui_effects_repeat '█' "$width")]"
    ui_effects_frame_done
}

ui_effects_typewriter() {
    local text="Loading system..." delay="0.025" i len

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --text)
                text="${2:-}"
                shift 2
                ;;
            --delay)
                delay="${2:-0.025}"
                shift 2
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done
    if ! ui_can_animate; then
        printf '  %s\n' "$text"
        return 0
    fi
    len="${#text}"
    i=1
    while [ "$i" -le "$len" ]; do
        printf '\r  '
        ui_color "$AIR_UI_COLOR_HINT" ">"
        printf ' %s' "${text:0:i}"
        ui_color "$AIR_UI_COLOR_MUTED" " █"
        ui_effects_sleep "$delay"
        i=$((i + 1))
    done
    printf '\n'
}

ui_effects_wave() {
    local text="Processing data" delay="0.05" loops=1 i j len ch

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --text)
                text="${2:-}"
                shift 2
                ;;
            --delay)
                delay="${2:-0.05}"
                shift 2
                ;;
            --loops)
                loops="${2:-1}"
                shift 2
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done
    if ! ui_can_animate; then
        printf '  %s\n' "$text"
        return 0
    fi
    len="${#text}"
    i=0
    while [ "$i" -lt $((len * loops)) ]; do
        printf '\r  '
        j=0
        while [ "$j" -lt "$len" ]; do
            ch="${text:j:1}"
            if [ "$j" -eq $((i % len)) ]; then
                ui_color "$AIR_UI_COLOR_HINT" "$ch"
            else
                ui_color "$AIR_UI_COLOR_MUTED" "$ch"
            fi
            j=$((j + 1))
        done
        ui_effects_sleep "$delay"
        i=$((i + 1))
    done
    printf '\n'
}

ui_effects_cursor() {
    local prompt="input" value="my-app" frames=6 delay="0.18" i cursor

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --prompt)
                prompt="${2:-input}"
                shift 2
                ;;
            --value)
                value="${2:-}"
                shift 2
                ;;
            --frames)
                frames="${2:-6}"
                shift 2
                ;;
            --delay)
                delay="${2:-0.18}"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    if ! ui_can_animate; then
        printf '  %s:\n  > %s █\n' "$prompt" "$value"
        return 0
    fi
    printf '  '
    ui_color "$AIR_UI_COLOR_TITLE" "$prompt:"
    printf '\n'
    i=0
    while [ "$i" -lt "$frames" ]; do
        if [ $((i % 2)) -eq 0 ]; then
            cursor="█"
        else
            cursor=" "
        fi
        printf '\r  '
        ui_color "$AIR_UI_COLOR_HINT" ">"
        printf ' %s ' "$value"
        ui_color "$AIR_UI_COLOR_HINT" "$cursor"
        ui_effects_sleep "$delay"
        i=$((i + 1))
    done
    printf '\n'
}

ui_effects_reveal() {
    local text="Hello World" delay="0.035" mask="█" i len

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --text)
                text="${2:-}"
                shift 2
                ;;
            --delay)
                delay="${2:-0.035}"
                shift 2
                ;;
            --mask)
                mask="${2:-█}"
                shift 2
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done
    if ! ui_can_animate; then
        printf '  %s\n' "$text"
        return 0
    fi
    len="${#text}"
    i=0
    while [ "$i" -le "$len" ]; do
        printf '\r  '
        ui_color "$AIR_UI_COLOR_HINT" "${text:0:i}"
        ui_color "$AIR_UI_COLOR_MUTED" "$(ui_effects_repeat "$mask" "$((len - i))")"
        ui_effects_sleep "$delay"
        i=$((i + 1))
    done
    printf '\n'
}

ui_effects_gradient() {
    local text="Cloud AI" i len ch
    local -a colors

    colors=("$AIR_UI_COLOR_HINT" "$AIR_UI_COLOR_ACCENT" "$AIR_UI_COLOR_OK" "$AIR_UI_COLOR_WARNING")
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --text)
                text="${2:-}"
                shift 2
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done
    printf '  '
    if ! ui_supports_color; then
        printf '%s\n' "$text"
        return 0
    fi
    len="${#text}"
    i=0
    while [ "$i" -lt "$len" ]; do
        ch="${text:i:1}"
        ui_color "${colors[$((i % ${#colors[@]}))]}" "$ch"
        i=$((i + 1))
    done
    printf '\n'
}

ui_effects_heatmap() {
    local label="" values="1 3 5 7 9" value block

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --label)
                label="${2:-}"
                shift 2
                ;;
            --values)
                values="${2:-}"
                shift 2
                ;;
            *)
                values="$*"
                break
                ;;
        esac
    done
    [ -n "$label" ] && {
        printf '  '
        ui_color "$AIR_UI_COLOR_MUTED" "$label"
        printf ' '
    }
    for value in $values; do
        case "$value" in
            ''|*[!0-9]*) block="░" ;;
            0|1|2) block="░" ;;
            3|4|5) block="▒" ;;
            6|7) block="▓" ;;
            *) block="█" ;;
        esac
        ui_color "$AIR_UI_COLOR_HINT" "$block"
    done
    printf '\n'
}

ui_effects_highlight() {
    local text="This file is used for parsing JSON" match="JSON" prefix suffix

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --text)
                text="${2:-}"
                shift 2
                ;;
            --match|--needle)
                match="${2:-}"
                shift 2
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done
    printf '  '
    if [ -n "$match" ] && [ "${text#*"$match"}" != "$text" ]; then
        prefix="${text%%"$match"*}"
        suffix="${text#*"$match"}"
        printf '%s' "$prefix"
        ui_color "$AIR_UI_COLOR_ACCENT" "$match"
        printf '%s\n' "$suffix"
    else
        printf '%s\n' "$text"
    fi
}

ui_effects_morph() {
    local from="STEP 1" to="STEP 2" delay="0.04" i max frame

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --from)
                from="${2:-}"
                shift 2
                ;;
            --to)
                to="${2:-}"
                shift 2
                ;;
            --delay)
                delay="${2:-0.04}"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    if ! ui_can_animate; then
        printf '  %s\n' "$to"
        return 0
    fi
    max="${#to}"
    [ "${#from}" -gt "$max" ] && max="${#from}"
    i=0
    while [ "$i" -le "$max" ]; do
        frame="${to:0:i}${from:i}"
        printf '\r  '
        ui_color "$AIR_UI_COLOR_HINT" "$frame"
        printf '%*s' "$((max - ${#frame}))" ''
        ui_effects_sleep "$delay"
        i=$((i + 1))
    done
    printf '\n'
}

ui_effects_particle() {
    local text="HELLO" delay="0.035" frames=10 glyphs="░▒▓█" i j len out pos

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --text)
                text="${2:-}"
                shift 2
                ;;
            --frames)
                frames="${2:-10}"
                shift 2
                ;;
            --delay)
                delay="${2:-0.035}"
                shift 2
                ;;
            --glyphs)
                glyphs="${2:-░▒▓█}"
                shift 2
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done
    if ! ui_can_animate; then
        printf '  %s\n' "$text"
        return 0
    fi
    case "$frames" in ''|*[!0-9]*) frames=10 ;; esac
    [ "$frames" -le 0 ] && frames=1
    len="${#text}"
    i=0
    while [ "$i" -le "$frames" ]; do
        out=""
        j=0
        while [ "$j" -lt "$len" ]; do
            if [ "$j" -lt $((len * i / frames)) ]; then
                out="${out}${text:j:1}"
            else
                pos=$((RANDOM % ${#glyphs}))
                out="${out}${glyphs:pos:1}"
            fi
            j=$((j + 1))
        done
        printf '\r  '
        ui_color "$AIR_UI_COLOR_HINT" "$out"
        ui_effects_sleep "$delay"
        i=$((i + 1))
    done
    printf '\n'
}

ui_effects_ghost() {
    local text="Loading" max=6 delay="0.08" i dots

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --text)
                text="${2:-Loading}"
                shift 2
                ;;
            --max)
                max="${2:-6}"
                shift 2
                ;;
            --delay)
                delay="${2:-0.08}"
                shift 2
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done
    if ! ui_can_animate; then
        printf '  %s...\n' "$text"
        return 0
    fi
    i="$max"
    while [ "$i" -ge 0 ]; do
        dots="$(printf '%*s' "$i" '' | tr ' ' '.')"
        printf '\r  %s%s%*s' "$text" "$dots" "$((max - i))" ''
        ui_effects_sleep "$delay"
        i=$((i - 1))
    done
    printf '\n'
}

ui_effects_example() {
    ui_effects_shimmer --label "Parsing data" --width 16 --frames 18 --delay 0.015
    ui_effects_typewriter --text "Streaming response..." --delay 0.01
    ui_effects_wave --text "Processing data" --delay 0.02
    ui_effects_cursor --prompt "Project name" --value "my-app" --frames 4 --delay 0.08
    ui_effects_reveal --text "Ready to continue" --delay 0.01
    ui_effects_morph --from "STEP 1" --to "STEP 2" --delay 0.02
    ui_effects_particle --text "HELLO" --frames 6 --delay 0.02
    ui_effects_gradient --text "Air UI"
    ui_effects_heatmap --label "load" --values "1 2 4 6 8 10"
    ui_effects_highlight --text "This file is used for parsing JSON" --match "JSON"
    ui_effects_ghost --text "Finishing" --max 4 --delay 0.03
}

ui_effects() {
    local command="${1:-help}"

    shift || true
    case "$command" in
        -h|--help|help) ui_effects_help ;;
        shimmer) ui_effects_shimmer "$@" ;;
        typewriter) ui_effects_typewriter "$@" ;;
        wave) ui_effects_wave "$@" ;;
        cursor|blink) ui_effects_cursor "$@" ;;
        reveal) ui_effects_reveal "$@" ;;
        gradient) ui_effects_gradient "$@" ;;
        heatmap) ui_effects_heatmap "$@" ;;
        highlight) ui_effects_highlight "$@" ;;
        morph) ui_effects_morph "$@" ;;
        particle) ui_effects_particle "$@" ;;
        ghost) ui_effects_ghost "$@" ;;
        example) ui_effects_example "$@" ;;
        *)
            ui check-item error "ui effects" "Unknown effect: $command"
            return 1
            ;;
    esac
}

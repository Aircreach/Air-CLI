# Air UI layout components.

ui_layout_strip_ansi() {
    sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g'
}

ui_layout_visible_len() {
    local text="$1"

    printf '%s' "$text" | ui_layout_strip_ansi | wc -m | awk '{print $1}'
}

ui_layout_pad_right() {
    local text="$1" width="$2" len spaces

    len="$(ui_layout_visible_len "$text")"
    printf '%s' "$text"
    spaces=$((width - len))
    while [ "$spaces" -gt 0 ]; do
        printf ' '
        spaces=$((spaces - 1))
    done
}

ui_layout_read_content() {
    local content=""

    if [ "$#" -gt 0 ]; then
        while [ "$#" -gt 0 ]; do
            content="${content}${content:+
}$1"
            shift
        done
        printf '%s\n' "$content"
    elif [ ! -t 0 ]; then
        cat
    fi
}

ui_layout_height_value() {
    local value="${1:-auto}" fallback="${2:-10}"

    case "$value" in
        auto|fill)
            printf '%s\n' "$value"
            ;;
        max:*)
            value="${value#max:}"
            case "$value" in ''|*[!0-9]*) printf '%s\n' "$fallback" ;; *) printf 'max:%s\n' "$value" ;; esac
            ;;
        ''|*[!0-9]*)
            printf '%s\n' "$fallback"
            ;;
        *)
            printf '%s\n' "$value"
            ;;
    esac
}

ui_layout_content_line_count() {
    sed '/^$/!b;${d;}' | wc -l | awk '{print $1}'
}

ui_layout_stack() {
    local title="" gap=1 content="" line gap_index

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --title)
                title="${2:-}"
                shift 2
                ;;
            --gap)
                gap="${2:-1}"
                shift 2
                ;;
            *)
                content="${content}${content:+
}$1"
                shift
                ;;
        esac
    done
    case "$gap" in ''|*[!0-9]*) gap=1 ;; esac
    if [ -z "$content" ] && [ ! -t 0 ]; then
        content="$(cat)"
    fi

    [ -n "$title" ] && {
        printf '  '
        ui_color "$AIR_UI_COLOR_HEADER" "$title"
        printf '\n'
    }
    printf '%s\n' "$content" | while IFS= read -r line || [ -n "$line" ]; do
        printf '  %s\n' "$line"
    done
    gap_index=0
    while [ "$gap_index" -lt "$gap" ]; do
        printf '\n'
        gap_index=$((gap_index + 1))
    done
}

ui_layout_split() {
    local left_file="" right_file="" left_width="" gap="3" direction="horizontal" width max right_width
    local i=0 left_line="" right_line=""
    local -a left_lines right_lines

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --left|--left-file)
                left_file="${2:-}"
                shift 2
                ;;
            --right|--right-file)
                right_file="${2:-}"
                shift 2
                ;;
            --left-width)
                left_width="${2:-}"
                shift 2
                ;;
            --direction)
                direction="${2:-horizontal}"
                shift 2
                ;;
            --gap)
                gap="${2:-3}"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    [ -r "$left_file" ] || return 1
    [ -r "$right_file" ] || return 1

    width="$(ui_terminal_width)"
    case "$gap" in ''|*[!0-9]*) gap=3 ;; esac
    case "$left_width" in ''|*[!0-9]*) left_width=$((width * 58 / 100)) ;; esac
    right_width=$((width - left_width - gap - 2))

    mapfile -t left_lines < "$left_file"
    mapfile -t right_lines < "$right_file"

    if [ "$direction" = "vertical" ] || [ "$width" -lt 92 ] || [ "$right_width" -lt 24 ]; then
        for left_line in "${left_lines[@]}"; do
            printf '  %s\n' "$left_line"
        done
        printf '\n'
        for right_line in "${right_lines[@]}"; do
            printf '  %s\n' "$right_line"
        done
        return 0
    fi

    max="${#left_lines[@]}"
    [ "${#right_lines[@]}" -gt "$max" ] && max="${#right_lines[@]}"
    while [ "$i" -lt "$max" ]; do
        left_line="${left_lines[i]:-}"
        right_line="${right_lines[i]:-}"
        printf '  '
        ui_layout_pad_right "$left_line" "$left_width"
        printf '%*s' "$gap" ''
        printf '%s\n' "$right_line"
        i=$((i + 1))
    done
}

ui_layout_grid() {
    local columns=2 gap=3 title="" content="" width col_width row line field index
    local -a fields

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --columns|--cols)
                columns="${2:-2}"
                shift 2
                ;;
            --gap)
                gap="${2:-3}"
                shift 2
                ;;
            --title)
                title="${2:-}"
                shift 2
                ;;
            *)
                content="${content}${content:+
}$1"
                shift
                ;;
        esac
    done
    case "$columns" in ''|*[!0-9]*) columns=2 ;; esac
    [ "$columns" -lt 1 ] && columns=1
    case "$gap" in ''|*[!0-9]*) gap=3 ;; esac
    if [ -z "$content" ] && [ ! -t 0 ]; then
        content="$(cat)"
    fi
    [ -n "$title" ] && {
        printf '  '
        ui_color "$AIR_UI_COLOR_HEADER" "$title"
        printf '\n'
    }
    width="$(ui_terminal_width)"
    col_width=$(((width - 4 - (columns - 1) * gap) / columns))
    [ "$col_width" -lt 12 ] && col_width=12
    while IFS= read -r line || [ -n "$line" ]; do
        fields+=("$line")
    done <<EOF_GRID
$content
EOF_GRID
    index=0
    while [ "$index" -lt "${#fields[@]}" ]; do
        printf '  '
        row=0
        while [ "$row" -lt "$columns" ] && [ "$index" -lt "${#fields[@]}" ]; do
            field="${fields[index]}"
            ui_layout_pad_right "$field" "$col_width"
            row=$((row + 1))
            index=$((index + 1))
            [ "$row" -lt "$columns" ] && printf '%*s' "$gap" ''
        done
        printf '\n'
    done
}

ui_layout_indent_file() {
    local indent="${1:-2}" prefix line

    case "$indent" in ''|*[!0-9]*) indent=2 ;; esac
    prefix="$(printf '%*s' "$indent" '')"
    while IFS= read -r line || [ -n "$line" ]; do
        printf '%s%s\n' "$prefix" "$line"
    done
}

ui_layout_rail() {
    local current=1 index=1 title indent=2 prefix style="step" state label rest marker_state
    local numbers=1 number_width=2 number_text

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --current)
                current="${2:-1}"
                shift 2
                ;;
            --style)
                style="${2:-step}"
                shift 2
                ;;
            --indent)
                indent="${2:-2}"
                shift 2
                ;;
            --numbers)
                numbers="${2:-1}"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    case "$current" in ''|*[!0-9]*) current=1 ;; esac
    case "$indent" in ''|*[!0-9]*) indent=2 ;; esac
    case "$numbers" in yes|true|on) numbers=1 ;; no|false|off) numbers=0 ;; ''|*[!0-9]*) numbers=1 ;; esac
    case "$style" in nav) [ "$numbers" = "1" ] && numbers=0 ;; esac
    prefix="$(printf '%*s' "$indent" '')"

    while IFS= read -r title || [ -n "$title" ]; do
        [ -n "$title" ] || title="Step $index"
        state=""
        label="$title"
        rest=""
        case "$title" in
            *"	"*)
                IFS="	" read -r state label rest _ <<EOF_RAIL
$title
EOF_RAIL
                ;;
        esac
        [ -n "$label" ] || label="$title"
        printf '%s' "$prefix"
        if [ -n "$state" ] && [ "$style" = "status" ]; then
            marker_state="$state"
        elif [ "$index" -lt "$current" ]; then
            marker_state=done
        elif [ "$index" -eq "$current" ]; then
            marker_state=current
        else
            marker_state=pending
        fi
        ui marker "$marker_state" --style bracket
        if [ "$numbers" = "1" ]; then
            printf -v number_text "%0${number_width}d" "$index"
            printf ' '
            ui_color "$AIR_UI_COLOR_MUTED" "$number_text"
        fi
        printf ' '
        if [ "$index" -eq "$current" ]; then
            ui_color "$AIR_UI_COLOR_TITLE" "$label"
        else
            printf '%s' "$label"
        fi
        [ -n "$rest" ] && {
            printf '  '
            ui_color "$AIR_UI_COLOR_MUTED" "$rest"
        }
        printf '\n'
        index=$((index + 1))
    done
}

ui_layout_step_rail() {
    ui_layout_rail "$@"
}

ui_layout_wizard() {
    local current=1 total="" title="" message="" next="" steps_file="" kind="" body_file="" log_file="" log_height=8 rail="right"
    local left_file right_file main_file step_label body_has_content=0

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --current)
                current="${2:-1}"
                shift 2
                ;;
            --total)
                total="${2:-}"
                shift 2
                ;;
            --title)
                title="${2:-}"
                shift 2
                ;;
            --message)
                message="${2:-}"
                shift 2
                ;;
            --body|--body-file|--main)
                body_file="${2:-}"
                shift 2
                ;;
            --log|--log-file)
                log_file="${2:-}"
                shift 2
                ;;
            --log-height)
                log_height="${2:-8}"
                shift 2
                ;;
            --rail)
                rail="${2:-right}"
                shift 2
                ;;
            --next)
                next="${2:-}"
                shift 2
                ;;
            --steps-file)
                steps_file="${2:-}"
                shift 2
                ;;
            --kind|--type)
                kind="${2:-}"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    case "$current" in ''|*[!0-9]*) current=1 ;; esac
    [ -n "$total" ] || total="$current"
    case "$total" in ''|*[!0-9]*) total="$current" ;; esac
    [ -r "$steps_file" ] || return 1

    left_file="$(mktemp)"
    right_file="$(mktemp)"
    main_file="$(mktemp)"
    step_label="Step $current/$total"
    [ -r "$body_file" ] && [ -s "$body_file" ] && body_has_content=1
    {
        ui marker current --style bare
        printf ' '
        ui_color "$AIR_UI_COLOR_HEADER" "$step_label"
        [ -n "$kind" ] && {
            printf ' '
            ui_badge "$kind" hint
        }
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "${title:-Step $current}"
        printf '\n'
        [ -n "$message" ] && {
            printf '\n'
            ui_text "$message"
        }
        if [ "$body_has_content" = "1" ]; then
            printf '\n'
            cat "$body_file"
        fi
        [ -n "$next" ] && {
            printf '\n'
            ui_color "$AIR_UI_COLOR_MUTED" "Next:"
            printf ' %s\n' "$next"
        }
    } > "$main_file"
    if [ -r "$log_file" ]; then
        {
            cat "$main_file"
            printf '\n'
            ui_layout_viewport --title "Output" --height "$log_height" < "$log_file"
        } > "$left_file"
    else
        cp "$main_file" "$left_file"
    fi
    {
        ui_color "$AIR_UI_COLOR_HEADER" "Steps"
        printf '\n'
        ui_layout_rail --current "$current" --indent 0 < "$steps_file"
    } > "$right_file"

    case "$rail" in
        left)
            ui_layout_split --left "$right_file" --right "$left_file" --left-width "$(( $(ui_terminal_width) * 28 / 100 ))"
            ;;
        none|off)
            cat "$left_file"
            ;;
        right|*)
            ui_layout_split --left "$left_file" --right "$right_file" --left-width "$(( $(ui_terminal_width) * 62 / 100 ))"
            ;;
    esac
    rm -f "$left_file" "$right_file" "$main_file"
}

ui_layout_viewport() {
    local title="" lines=10 height="" content="" total=0 skipped=0 line color mode

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --title)
                title="${2:-}"
                shift 2
                ;;
            --lines|--height)
                height="${2:-10}"
                shift 2
                ;;
            --follow)
                shift
                ;;
            *)
                content="${content}${content:+
}$1"
                shift
                ;;
        esac
    done
    mode="$(ui_layout_height_value "${height:-$lines}" 10)"
    if [ -z "$content" ] && [ ! -t 0 ]; then
        content="$(cat)"
    fi

    total="$(printf '%s\n' "$content" | sed '/^$/!b;${d;}' | wc -l | awk '{print $1}')"
    case "$mode" in
        auto|fill)
            lines="$total"
            ;;
        max:*)
            lines="${mode#max:}"
            [ "$total" -lt "$lines" ] && lines="$total"
            ;;
        *)
            lines="$mode"
            ;;
    esac
    case "$lines" in ''|*[!0-9]*) lines=10 ;; esac
    [ "$lines" -lt 1 ] && lines=1
    skipped=$((total - lines))
    [ "$skipped" -lt 0 ] && skipped=0
    color="$AIR_UI_COLOR_PANEL"

    printf '  '
    if ui_icon_enabled; then
        ui_color "$color" "╭─"
    else
        ui_color "$color" "+--"
    fi
    [ -n "$title" ] && {
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "$title"
    }
    [ "$skipped" -gt 0 ] && {
        printf ' '
        ui_color "$AIR_UI_COLOR_MUTED" "last $lines of $total lines"
    }
    printf '\n'
    [ "$skipped" -gt 0 ] && {
        printf '  '
        ui_color "$color" "$(ui_icon panel)"
        printf '  '
        ui_color "$AIR_UI_COLOR_MUTED" "... $skipped earlier line(s)"
        printf '\n'
    }
    printf '%s\n' "$content" | tail -n "$lines" | while IFS= read -r line || [ -n "$line" ]; do
        printf '  '
        ui_color "$color" "$(ui_icon panel)"
        printf '  %s\n' "$line"
    done
    printf '  '
    if ui_icon_enabled; then
        ui_color "$color" "╰─"
    else
        ui_color "$color" "+--"
    fi
    printf '\n'
}

ui_layout_screen() {
    local title="" subtitle="" mode="" main_file="" side_file="" tmp_main

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --title)
                title="${2:-}"
                shift 2
                ;;
            --subtitle)
                subtitle="${2:-}"
                shift 2
                ;;
            --mode)
                mode="${2:-}"
                shift 2
                ;;
            --main)
                main_file="${2:-}"
                shift 2
                ;;
            --side)
                side_file="${2:-}"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    [ -r "$main_file" ] || {
        tmp_main="$(mktemp)"
        if [ ! -t 0 ]; then
            cat > "$tmp_main"
        fi
        main_file="$tmp_main"
    }
    if [ -n "$title" ]; then
        ui_color "$AIR_UI_COLOR_TITLE" "$title"
        [ -n "$mode" ] && {
            printf ' '
            ui_badge "$mode" hint
        }
        printf '\n'
    fi
    [ -n "$subtitle" ] && {
        printf '  '
        ui_color "$AIR_UI_COLOR_MUTED" "$subtitle"
        printf '\n\n'
    }
    if [ -r "$side_file" ]; then
        if [ "$(ui_terminal_width)" -lt 92 ]; then
            cat "$main_file" | while IFS= read -r line || [ -n "$line" ]; do
                printf '  %s\n' "$line"
            done
            printf '\n  '
            ui_color "$AIR_UI_COLOR_HEADER" "Side"
            printf '\n'
            cat "$side_file" | while IFS= read -r line || [ -n "$line" ]; do
                printf '  %s\n' "$line"
            done
            [ -n "$tmp_main" ] && rm -f "$tmp_main"
            return 0
        fi
        ui_layout_split --left "$main_file" --right "$side_file"
    else
        cat "$main_file"
    fi
    [ -n "$tmp_main" ] && rm -f "$tmp_main"
}

ui_layout_render_field() {
    local file="$1" key="$2"

    awk -F= -v key="$key" '
        $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
            value=$2
            sub(/^[[:space:]]*/, "", value)
            sub(/[[:space:]]*$/, "", value)
            gsub(/^"/, "", value)
            gsub(/"$/, "", value)
            print value
            exit
        }
    ' "$file"
}

ui_layout_render() {
    local file="${1:-}" layout current total title subtitle mode steps body log log_height rail dir
    local left right direction left_width columns gap height

    [ -r "$file" ] || {
        ui check-item error "ui layout render" "Layout file is not readable: $file"
        return 1
    }
    dir="$(cd "$(dirname "$file")" 2>/dev/null && pwd)"
    layout="$(ui_layout_render_field "$file" layout)"
    [ -n "$layout" ] || layout=screen
    current="$(ui_layout_render_field "$file" current)"
    total="$(ui_layout_render_field "$file" total)"
    title="$(ui_layout_render_field "$file" title)"
    subtitle="$(ui_layout_render_field "$file" subtitle)"
    mode="$(ui_layout_render_field "$file" mode)"
    steps="$(ui_layout_render_field "$file" steps_file)"
    body="$(ui_layout_render_field "$file" body_file)"
    log="$(ui_layout_render_field "$file" log_file)"
    log_height="$(ui_layout_render_field "$file" log_height)"
    rail="$(ui_layout_render_field "$file" rail)"
    left="$(ui_layout_render_field "$file" left_file)"
    right="$(ui_layout_render_field "$file" right_file)"
    direction="$(ui_layout_render_field "$file" direction)"
    left_width="$(ui_layout_render_field "$file" left_width)"
    columns="$(ui_layout_render_field "$file" columns)"
    gap="$(ui_layout_render_field "$file" gap)"
    height="$(ui_layout_render_field "$file" height)"
    case "$steps" in ''|/*) ;; *) steps="$dir/$steps" ;; esac
    case "$body" in ''|/*) ;; *) body="$dir/$body" ;; esac
    case "$log" in ''|/*) ;; *) log="$dir/$log" ;; esac
    case "$left" in ''|/*) ;; *) left="$dir/$left" ;; esac
    case "$right" in ''|/*) ;; *) right="$dir/$right" ;; esac

    case "$layout" in
        wizard)
            ui_layout_wizard --current "${current:-1}" --total "${total:-${current:-1}}" --title "$title" --message "$subtitle" --steps-file "$steps" --body "$body" --log "$log" --log-height "${log_height:-8}" --rail "${rail:-right}"
            ;;
        screen)
            ui_layout_screen --title "$title" --subtitle "$subtitle" --mode "$mode" --main "$body" --side "$steps"
            ;;
        split)
            ui_layout_split --left "${left:-$body}" --right "${right:-$steps}" --direction "${direction:-horizontal}" --left-width "$left_width" --gap "${gap:-3}"
            ;;
        stack)
            if [ -r "$body" ]; then
                ui_layout_stack --title "$title" --gap "${gap:-1}" < "$body"
            else
                ui check-item error "ui layout render" "Missing body_file for stack layout."
                return 1
            fi
            ;;
        grid)
            if [ -r "$body" ]; then
                ui_layout_grid --title "$title" --columns "${columns:-2}" --gap "${gap:-3}" < "$body"
            else
                ui check-item error "ui layout render" "Missing body_file for grid layout."
                return 1
            fi
            ;;
        viewport)
            if [ -r "$body" ]; then
                ui_layout_viewport --title "$title" --height "${height:-${log_height:-10}}" < "$body"
            else
                ui check-item error "ui layout render" "Missing body_file for viewport layout."
                return 1
            fi
            ;;
        *)
            ui check-item error "ui layout render" "Unsupported layout: $layout"
            return 1
            ;;
    esac
}

ui_layout() {
    local command="${1:-}"

    shift || true
    case "$command" in
        -h|--help|help)
            ui command-help <<'EOF'
# ui layout

Reusable terminal layout primitives.

Usage:
  ui layout stack [--gap n] [--title text] < content
  ui layout split --left <file> --right <file> [--left-width n]
  ui layout grid [--columns n] [--gap n] < rows.txt
  ui layout rail --current <n> [--style step|status|nav] < steps.txt
  ui layout screen --title <text> --main <file> [--side <file>]
  ui layout wizard --current <n> --total <n> --title <text> --steps-file <file> [--body <file>] [--log <file>]
  ui layout viewport --title <text> --height <n|max:n|auto> < output.log
  ui layout render <layout.toml>
  ui layout example
EOF
            ;;
        example)
            local steps_file body_file side_file layout_file log_file
            ui title "Layout Example"
            steps_file="$(mktemp)"
            body_file="$(mktemp)"
            side_file="$(mktemp)"
            layout_file="$(mktemp)"
            log_file="$(mktemp)"
            {
                printf 'Check shell\n'
                printf 'Choose build path\n'
                printf 'Build helper\n'
                printf 'Preview\n'
            } > "$steps_file"
            {
                printf 'Current work stays on the left.\n'
                printf 'The rail keeps flow context visible.\n'
            } > "$body_file"
            {
                printf 'helper UI\n'
                printf 'basic fallback\n'
                printf 'plain safe\n'
            } > "$side_file"
            {
                printf 'fetch runtime\n'
                printf 'mount workspace\n'
                printf 'compile helper\n'
                printf 'write binary\n'
            } > "$log_file"
            ui_layout_wizard --current 3 --total 4 --kind task --title "Build helper" --message "Wizard composes screen, rail, body, and viewport regions." --next "Preview" --steps-file "$steps_file" --body "$body_file" --log "$log_file" --log-height 3
            printf 'First line\nSecond line\n' | ui_layout_stack --title "Stack auto height" --gap 0
            printf 'Existing Go\nDocker container\nAir local Go\nSystem apt\nExit\n' | ui_layout_grid --title "Grid" --columns 2
            ui_layout_screen --title "Screen" --subtitle "Main region with optional side context." --mode "basic" --main "$body_file" --side "$side_file"
            printf 'done	Check shell\ncurrent	Build helper\npending	Preview\n' | ui_layout_rail --style status --current 2
            ui_layout_viewport --title "Build output" --height max:3 < "$log_file"
            {
                printf 'layout = "wizard"\n'
                printf 'title = "Rendered layout"\n'
                printf 'subtitle = "TOML spec with relative paths."\n'
                printf 'current = 2\n'
                printf 'total = 4\n'
                printf 'steps_file = "%s"\n' "$steps_file"
                printf 'body_file = "%s"\n' "$body_file"
                printf 'log_file = "%s"\n' "$log_file"
                printf 'log_height = 2\n'
            } > "$layout_file"
            ui_layout_render "$layout_file"
            rm -f "$steps_file" "$body_file" "$side_file" "$layout_file" "$log_file"
            ;;
        stack) ui_layout_stack "$@" ;;
        split) ui_layout_split "$@" ;;
        grid) ui_layout_grid "$@" ;;
        rail|step-rail|steps) ui_layout_rail "$@" ;;
        viewport|log-panel|output) ui_layout_viewport "$@" ;;
        screen) ui_layout_screen "$@" ;;
        wizard) ui_layout_wizard "$@" ;;
        render) ui_layout_render "$@" ;;
        *)
            ui check-item error "ui layout" "Unknown layout command: $command"
            return 1
            ;;
    esac
}

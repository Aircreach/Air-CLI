# Air UI interactive components.

ui_confirm() {
    if [ "${1:-}" = "example" ]; then
        ui title "Confirm Example"
        printf '  Delete file?\n\n  '
        ui_color "$AIR_UI_COLOR_HINT" "[y]"
        printf ' Yes   '
        ui_color "$AIR_UI_COLOR_MUTED" "[n]"
        printf ' No  '
        ui_color "$AIR_UI_COLOR_MUTED" "[y/N]"
        printf '\n\n'
        printf '  Are you sure?\n  '
        ui_color "$AIR_UI_COLOR_HINT" ">"
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "Yes"
        printf '\n    No\n'
        return 0
    fi

    local title="" message="" default="" risk="medium" non_tty="deny" style="inline"
    local answer suffix question selected

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --title)
                title="${2:-}"
                shift 2
                ;;
            --message)
                message="${2:-}"
                shift 2
                ;;
            --default)
                default="${2:-}"
                shift 2
                ;;
            --risk)
                risk="${2:-medium}"
                shift 2
                ;;
            --style)
                style="${2:-inline}"
                shift 2
                ;;
            --non-tty|--non-interactive)
                non_tty="${2:-deny}"
                shift 2
                ;;
            *)
                message="${message:+$message }$1"
                shift
                ;;
        esac
    done

    [ -n "$default" ] || default="$(ui_risk_default "$risk")"
    [ "${AIR_YES:-0}" = "1" ] && return 0

    if ! ui_is_interactive; then
        case "$non_tty:$default" in
            allow:*|default:yes|yes:*) return 0 ;;
            *) return 1 ;;
        esac
    fi

    question="${message:-${title:-Continue?}}"

    case "$default" in
        yes) suffix='Y/n' ;;
        *) suffix='y/N' ;;
    esac

    if [ "$style" = "menu" ]; then
        selected="$(
            ui select \
                --style menu \
                --prompt "$question" \
                --default "$default" \
                --option 'yes	Yes' \
                --option 'no	No'
        )" || return 1
        [ "$selected" = "yes" ]
        return
    fi

    while :; do
        printf '  ' >&2
        ui_color "$AIR_UI_COLOR_TITLE" "$question" >&2
        printf '\n\n  ' >&2
        ui_color "$AIR_UI_COLOR_HINT" "[y]" >&2
        printf ' Yes   ' >&2
        ui_color "$AIR_UI_COLOR_MUTED" "[n]" >&2
        printf ' No' >&2
        printf '  ' >&2
        ui_color "$AIR_UI_COLOR_MUTED" "[$suffix]" >&2
        printf ' ' >&2
        IFS= read -r answer || return 1
        printf '\n' >&2
        case "$answer" in
            '')
                [ "$default" = "yes" ]
                return
                ;;
            y|Y|yes|YES|Yes) return 0 ;;
            n|N|no|NO|No) return 1 ;;
            *) printf '  Please answer yes or no.\n' >&2 ;;
        esac
    done
}

ui_input() {
    if [ "${1:-}" = "example" ]; then
        ui title "Input Example"
        printf '  '
        ui_color "$AIR_UI_COLOR_HINT" "$(ui_icon input)"
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "Project name"
        printf ' '
        ui_badge "default: my-app" hint
        printf '\n  '
        ui_color "$AIR_UI_COLOR_HINT" ">"
        printf ' my-app '
        ui_color "$AIR_UI_COLOR_HINT" "█"
        printf '\n'
        return 0
    fi

    local prompt="" default="" required=0 value icon

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --prompt)
                prompt="${2:-}"
                shift 2
                ;;
            --default)
                default="${2:-}"
                shift 2
                ;;
            --required)
                required=1
                shift
                ;;
            *)
                prompt="${prompt:-$1}"
                shift
                ;;
        esac
    done

    if ! ui_is_interactive; then
        if [ -n "$default" ] || [ "$required" = "0" ]; then
            printf '%s\n' "$default"
            return 0
        fi
        ui block error "Missing input" "$prompt requires a value in non-interactive mode." >&2
        return 1
    fi

    while :; do
        printf '  ' >&2
        icon="$(ui_icon input)"
        ui_color "$AIR_UI_COLOR_HINT" "$icon" >&2
        printf ' ' >&2
        ui_color "$AIR_UI_COLOR_TITLE" "${prompt:-Input}" >&2
        if [ -n "$default" ]; then
            printf ' ' >&2
            ui_badge "default: $default" hint >&2
        fi
        printf '\n  ' >&2
        ui_color "$AIR_UI_COLOR_HINT" ">" >&2
        printf ' ' >&2
        if [ -n "$default" ]; then
            if command -v bind >/dev/null 2>&1; then
                bind 'set enable-bracketed-paste off' >/dev/null 2>&1 || true
            fi
            IFS= read -e -r -i "$default" value || return 1
        else
            IFS= read -r value || return 1
        fi
        value="${value:-$default}"
        if [ -n "$value" ] || [ "$required" = "0" ]; then
            printf '%s\n' "$value"
            return 0
        fi
        ui block warning "Value required" "$prompt cannot be empty." >&2
    done
}

ui_password() {
    if [ "${1:-}" = "example" ]; then
        ui title "Password Example"
        printf '  '
        ui_color "$AIR_UI_COLOR_HINT" "$(ui_icon input)"
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "Token"
        printf ' '
        ui_badge "hidden" warning
        printf '\n  '
        ui_color "$AIR_UI_COLOR_HINT" ">"
        printf ' ••••••••\n'
        return 0
    fi

    local prompt="Password" required=0 value icon

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --prompt)
                prompt="${2:-Password}"
                shift 2
                ;;
            --required)
                required=1
                shift
                ;;
            *)
                prompt="${prompt:-$1}"
                shift
                ;;
        esac
    done

    if ! ui_is_interactive; then
        ui block error "Missing input" "$prompt requires an interactive terminal." >&2
        return 1
    fi

    while :; do
        printf '  ' >&2
        ui_color "$AIR_UI_COLOR_HINT" "$(ui_icon input)" >&2
        printf ' ' >&2
        ui_color "$AIR_UI_COLOR_TITLE" "${prompt:-Password}" >&2
        printf ' ' >&2
        ui_badge "hidden" warning >&2
        printf '\n  ' >&2
        ui_color "$AIR_UI_COLOR_HINT" ">" >&2
        printf ' ' >&2
        IFS= read -rs value || return 1
        printf '\n' >&2
        if [ -n "$value" ] || [ "$required" = "0" ]; then
            printf '%s\n' "$value"
            return 0
        fi
        ui block warning "Value required" "$prompt cannot be empty." >&2
    done
}

ui_select_resolve_answer() {
    local answer="$1" count="$2" i

    case "$answer" in
        ''|*[!0-9]*)
            i=0
            while [ "$i" -lt "$count" ]; do
                if [ "$answer" = "${values[i]}" ] || [ "$answer" = "${labels[i]}" ]; then
                    printf '%s\n' "${values[i]}"
                    return 0
                fi
                i=$((i + 1))
            done
            ;;
        *)
            [ "$answer" -ge 1 ] 2>/dev/null || return 1
            [ "$answer" -le "$count" ] 2>/dev/null || return 1
            printf '%s\n' "${values[$((answer - 1))]}"
            return 0
            ;;
    esac
    return 1
}

ui_select() {
    if [ "${1:-}" = "example" ]; then
        ui title "Select Example"
        printf '  Project type\n'
        printf '  '
        ui_color "$AIR_UI_COLOR_MUTED" "↑/↓ or j/k move, Enter selects."
        printf '\n  '
        ui marker current --style bare
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "Web App"
        printf '\n    CLI Tool\n    Library\n\n'
        printf '  Radio style\n  '
        ui marker done --style bare
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "Web App"
        printf '\n  '
        ui_color "$AIR_UI_COLOR_MUTED" "○"
        printf ' CLI Tool\n  '
        ui_color "$AIR_UI_COLOR_MUTED" "○"
        printf ' Library\n'
        return 0
    fi

    local prompt="" default="" options="" option selected value label hint
    local -a values labels hints
    local index=0 count=0 i key rest default_index=0 default_match=0 rendered=0 line_count=0
    local active_marker inactive_marker
    local style="${AIR_UI_SELECT_STYLE:-menu}" answer

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --prompt)
                prompt="${2:-}"
                shift 2
                ;;
            --default)
                default="${2:-}"
                shift 2
                ;;
            --style)
                style="${2:-menu}"
                shift 2
                ;;
            --option)
                options="${options}${options:+
}${2:-}"
                shift 2
                ;;
            *)
                options="${options}${options:+
}$1"
                shift
                ;;
        esac
    done

    while IFS= read -r option; do
        [ -n "$option" ] || continue
        value="$option"
        label=""
        hint=""
        case "$option" in
            *"	"*)
                IFS="	" read -r value label hint _ <<EOF_OPT
$option
EOF_OPT
                ;;
        esac
        [ -n "$value" ] || continue
        [ -n "$label" ] || label="$value"
        values+=("$value")
        labels+=("$label")
        hints+=("$hint")
        if [ -n "$default" ] && { [ "$value" = "$default" ] || [ "$label" = "$default" ]; }; then
            default_index="$count"
            default_match=1
        fi
        count=$((count + 1))
    done <<EOF
$options
EOF
    [ "$count" -gt 0 ] || return 1
    [ "$default_match" = "1" ] || default_index=0
    index="$default_index"

    if ! ui_is_interactive; then
        printf '%s\n' "${values[index]}"
        return 0
    fi

    if [ -n "$prompt" ]; then
        printf '  ' >&2
        ui_color "$AIR_UI_COLOR_HEADER" "$prompt" >&2
        printf '\n' >&2
    fi

    case "$style" in
        prompt)
            printf '  Select [%s]: ' "${labels[index]}" >&2
            IFS= read -r answer || return 1
            answer="${answer:-${values[index]}}"
            selected="$(ui_select_resolve_answer "$answer" "$count" 2>/dev/null || printf '%s\n' "$answer")"
            printf '%s\n' "$selected"
            return 0
            ;;
        list|numbered)
            i=0
            while [ "$i" -lt "$count" ]; do
                printf '    %s) %s' $((i + 1)) "${labels[i]}" >&2
                if [ -n "${hints[i]}" ]; then
                    printf '  ' >&2
                    ui_color "$AIR_UI_COLOR_MUTED" "${hints[i]}" >&2
                fi
                printf '\n' >&2
                i=$((i + 1))
            done
            while :; do
                printf '  Select [%s]: ' "${labels[index]}" >&2
                IFS= read -r answer || return 1
                answer="${answer:-$((index + 1))}"
                selected="$(ui_select_resolve_answer "$answer" "$count" 2>/dev/null || true)"
                [ -n "$selected" ] && {
                    printf '%s\n' "$selected"
                    return 0
                }
                printf '  Invalid selection.\n' >&2
            done
            ;;
    esac

    printf '  ' >&2
    ui_color "$AIR_UI_COLOR_MUTED" "↑/↓ or j/k move, Enter selects." >&2
    printf '\n' >&2
    line_count=$((count + 1))
    case "$style" in
        radio)
            active_marker="radio"
            inactive_marker="○"
            ;;
        *)
            active_marker="pointer"
            inactive_marker=" "
            ;;
    esac
    while :; do
        if [ "$rendered" = "1" ]; then
            printf '\033[%sA' "$line_count" >&2
        fi
        i=0
        while [ "$i" -lt "$count" ]; do
            printf '\r\033[2K' >&2
            if [ "$i" -eq "$index" ]; then
                printf '  ' >&2
                if [ "$active_marker" = "radio" ]; then
                    ui marker done --style bare >&2
                else
                    ui marker current --style bare >&2
                fi
                printf ' ' >&2
                ui_color "$AIR_UI_COLOR_TITLE" "${labels[i]}" >&2
                if [ -n "${hints[i]}" ]; then
                    printf '  ' >&2
                    ui_color "$AIR_UI_COLOR_MUTED" "${hints[i]}" >&2
                fi
                printf '\n' >&2
            else
                printf '  ' >&2
                ui_color "$AIR_UI_COLOR_MUTED" "$inactive_marker" >&2
                printf ' ' >&2
                printf '%s' "${labels[i]}" >&2
                if [ -n "${hints[i]}" ]; then
                    printf '  ' >&2
                    ui_color "$AIR_UI_COLOR_MUTED" "${hints[i]}" >&2
                fi
                printf '\n' >&2
            fi
            i=$((i + 1))
        done
        printf '\r\033[2K' >&2
        ui_color "$AIR_UI_COLOR_MUTED" "  q cancels" >&2
        printf '\n' >&2
        rendered=1

        IFS= read -rsn1 key || return 1
        case "$key" in
            '')
                selected="${values[index]}"
                printf '\n' >&2
                printf '%s\n' "$selected"
                return 0
                ;;
            $'\033')
                IFS= read -rsn2 -t 0.1 rest || rest=""
                case "$rest" in
                    '[A')
                        index=$((index - 1))
                        [ "$index" -lt 0 ] && index=$((count - 1))
                        ;;
                    '[B')
                        index=$((index + 1))
                        [ "$index" -ge "$count" ] && index=0
                        ;;
                esac
                ;;
            k|K)
                index=$((index - 1))
                [ "$index" -lt 0 ] && index=$((count - 1))
                ;;
            j|J)
                index=$((index + 1))
                [ "$index" -ge "$count" ] && index=0
                ;;
            q|Q)
                printf '\n' >&2
                return 1
                ;;
        esac
    done
}

ui_multiselect() {
    if [ "${1:-}" = "example" ]; then
        ui title "Multiselect Example"
        printf '  Targets\n'
        printf '  '
        ui marker current --style bare
        printf ' '
        ui marker done --style bracket
        printf ' bashrc\n    '
        ui marker pending --style bracket
        printf ' bash-env\n    '
        ui marker done --style bracket
        printf ' profile\n  '
        ui_color "$AIR_UI_COLOR_MUTED" "Space toggles, Enter accepts."
        printf '\n'
        return 0
    fi

    local prompt="" defaults="" options="" option value label hint token count=0 default_match index=0
    local rendered=0 line_count=0 key rest output
    local -a values labels hints selected_flags

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --prompt)
                prompt="${2:-}"
                shift 2
                ;;
            --default|--defaults)
                defaults="${2:-}"
                shift 2
                ;;
            --option)
                options="${options}${options:+
}${2:-}"
                shift 2
                ;;
            *)
                options="${options}${options:+
}$1"
                shift
                ;;
        esac
    done

    if ! ui_is_interactive; then
        printf '%s\n' "$defaults"
        [ -n "$defaults" ]
        return
    fi

    while IFS= read -r option; do
        [ -n "$option" ] || continue
        value="$option"
        label=""
        hint=""
        case "$option" in
            *"	"*)
                IFS="	" read -r value label hint _ <<EOF_OPT
$option
EOF_OPT
                ;;
        esac
        [ -n "$value" ] || continue
        [ -n "$label" ] || label="$value"
        default_match=0
        case ",$defaults," in *",$value,"*) default_match=1 ;; esac
        case " $defaults " in *" $value "*) default_match=1 ;; esac
        values+=("$value")
        labels+=("$label")
        hints+=("$hint")
        selected_flags+=("$default_match")
        count=$((count + 1))
    done <<EOF
$options
EOF
    [ "$count" -gt 0 ] || return 1
    index=0
    [ -n "$prompt" ] && {
        printf '  ' >&2
        ui_color "$AIR_UI_COLOR_HEADER" "$prompt" >&2
        printf '\n' >&2
    }
    printf '  ' >&2
    ui_color "$AIR_UI_COLOR_MUTED" "↑/↓ or j/k move, Space toggles, Enter accepts." >&2
    printf '\n' >&2
    line_count=$((count + 1))
    while :; do
        if [ "$rendered" = "1" ]; then
            printf '\033[%sA' "$line_count" >&2
        fi
        token=0
        while [ "$token" -lt "$count" ]; do
            printf '\r\033[2K' >&2
            if [ "$token" -eq "$index" ]; then
                printf '  ' >&2
                ui marker current --style bare >&2
            else
                printf '   ' >&2
            fi
            printf ' ' >&2
            if [ "${selected_flags[token]}" = "1" ]; then
                ui marker done --style bracket >&2
            else
                ui marker pending --style bracket >&2
            fi
            printf ' ' >&2
            if [ "$token" -eq "$index" ]; then
                ui_color "$AIR_UI_COLOR_TITLE" "${labels[token]}" >&2
            else
                printf '%s' "${labels[token]}" >&2
            fi
            if [ -n "${hints[token]}" ]; then
                printf '  ' >&2
                ui_color "$AIR_UI_COLOR_MUTED" "${hints[token]}" >&2
            fi
            printf '\n' >&2
            token=$((token + 1))
        done
        printf '\r\033[2K' >&2
        ui_color "$AIR_UI_COLOR_MUTED" "  q cancels" >&2
        printf '\n' >&2
        rendered=1

        IFS= read -rsn1 key || return 1
        case "$key" in
            '')
                output=""
                token=0
                while [ "$token" -lt "$count" ]; do
                    if [ "${selected_flags[token]}" = "1" ]; then
                        output="${output}${output:+,}${values[token]}"
                    fi
                    token=$((token + 1))
                done
                [ -n "$output" ] || return 1
                printf '\n' >&2
                printf '%s\n' "$output"
                return 0
                ;;
            ' ')
                if [ "${selected_flags[index]}" = "1" ]; then
                    selected_flags[index]=0
                else
                    selected_flags[index]=1
                fi
                ;;
            $'\033')
                IFS= read -rsn2 -t 0.1 rest || rest=""
                case "$rest" in
                    '[A')
                        index=$((index - 1))
                        [ "$index" -lt 0 ] && index=$((count - 1))
                        ;;
                    '[B')
                        index=$((index + 1))
                        [ "$index" -ge "$count" ] && index=0
                        ;;
                esac
                ;;
            k|K)
                index=$((index - 1))
                [ "$index" -lt 0 ] && index=$((count - 1))
                ;;
            j|J)
                index=$((index + 1))
                [ "$index" -ge "$count" ] && index=0
                ;;
            q|Q)
                printf '\n' >&2
                return 1
                ;;
        esac
    done
}

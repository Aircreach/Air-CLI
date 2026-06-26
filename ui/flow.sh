# Air UI flow runner. A flow is a linear, caller-owned UI composition.

ui_flow_toml_unquote() {
    local value="$1"

    value="${value%%#*}"
    value="${value%"${value##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%,}"
    case "$value" in
        \"*\")
            value="${value#\"}"
            value="${value%\"}"
            ;;
        \'*\')
            value="${value#\'}"
            value="${value%\'}"
            ;;
    esac
    printf '%s\n' "$value"
}

ui_flow_parse() {
    local file="$1" line section="" step_index=0 key value

    UI_FLOW_ID=""
    UI_FLOW_TITLE=""
    UI_FLOW_SUMMARY=""
    UI_FLOW_LAYOUT="wizard"
    UI_FLOW_LAYOUT_RAIL="right"
    UI_FLOW_LAYOUT_LOG_HEIGHT="8"
    UI_FLOW_LAYOUT_NARROW="stack"
    UI_FLOW_STEP_COUNT=0
    UI_FLOW_DIR="$(cd "$(dirname "$file")" 2>/dev/null && pwd)"

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"
        [ -n "$line" ] || continue

        case "$line" in
            '[[steps]]')
                step_index=$((step_index + 1))
                UI_FLOW_STEP_COUNT="$step_index"
                section=steps
                eval "UI_FLOW_STEP_${step_index}_ID=''"
                eval "UI_FLOW_STEP_${step_index}_TYPE='info'"
                eval "UI_FLOW_STEP_${step_index}_TITLE=''"
                eval "UI_FLOW_STEP_${step_index}_MESSAGE=''"
                eval "UI_FLOW_STEP_${step_index}_ACTION=''"
                eval "UI_FLOW_STEP_${step_index}_REQUIRED='false'"
                eval "UI_FLOW_STEP_${step_index}_DEFAULT=''"
                eval "UI_FLOW_STEP_${step_index}_RISK='medium'"
                eval "UI_FLOW_STEP_${step_index}_OPTIONS_ACTION=''"
                eval "UI_FLOW_STEP_${step_index}_SELECT_STYLE=''"
                continue
                ;;
            \[*\])
                section=other
                continue
                ;;
        esac

        case "$line" in
            *=*)
                key="${line%%=*}"
                key="${key%"${key##*[![:space:]]}"}"
                value="$(ui_flow_toml_unquote "${line#*=}")"
                ;;
            *)
                continue
                ;;
        esac

        if [ "$section" = "steps" ] && [ "$step_index" -gt 0 ]; then
            case "$key" in
                id) eval "UI_FLOW_STEP_${step_index}_ID=\$value" ;;
                type) eval "UI_FLOW_STEP_${step_index}_TYPE=\$value" ;;
                title) eval "UI_FLOW_STEP_${step_index}_TITLE=\$value" ;;
                message) eval "UI_FLOW_STEP_${step_index}_MESSAGE=\$value" ;;
                action) eval "UI_FLOW_STEP_${step_index}_ACTION=\$value" ;;
                required) eval "UI_FLOW_STEP_${step_index}_REQUIRED=\$value" ;;
                default) eval "UI_FLOW_STEP_${step_index}_DEFAULT=\$value" ;;
                risk) eval "UI_FLOW_STEP_${step_index}_RISK=\$value" ;;
                options_action) eval "UI_FLOW_STEP_${step_index}_OPTIONS_ACTION=\$value" ;;
                select_style) eval "UI_FLOW_STEP_${step_index}_SELECT_STYLE=\$value" ;;
            esac
            continue
        fi

        case "$key" in
            id) UI_FLOW_ID="$value" ;;
            title) UI_FLOW_TITLE="$value" ;;
            summary) UI_FLOW_SUMMARY="$value" ;;
            layout) UI_FLOW_LAYOUT="$value" ;;
            layout.rail) UI_FLOW_LAYOUT_RAIL="$value" ;;
            layout.log_height) UI_FLOW_LAYOUT_LOG_HEIGHT="$value" ;;
            layout.narrow) UI_FLOW_LAYOUT_NARROW="$value" ;;
        esac
    done < "$file"
}

ui_flow_step_field() {
    local index="$1" field="$2"

    eval "printf '%s\n' \"\${UI_FLOW_STEP_${index}_${field}:-}\""
}

ui_flow_plan() {
    local first last

    printf '  '
    ui_color "$AIR_UI_COLOR_HEADER" "Overview"
    printf '\n'
    first="$(ui_flow_step_field 1 TITLE)"
    last="$(ui_flow_step_field "${UI_FLOW_STEP_COUNT:-1}" TITLE)"
    printf '    '
    ui_badge "${UI_FLOW_STEP_COUNT:-0} steps" hint
    printf ' '
    ui_color "$AIR_UI_COLOR_MUTED" "start:"
    printf ' %s' "${first:-step 1}"
    printf '  '
    ui_color "$AIR_UI_COLOR_MUTED" "finish:"
    printf ' %s\n' "${last:-commit}"
}

ui_flow_step_titles() {
    local index=1 title

    while [ "$index" -le "${UI_FLOW_STEP_COUNT:-0}" ]; do
        title="$(ui_flow_step_field "$index" TITLE)"
        printf '%s\n' "${title:-Step $index}"
        index=$((index + 1))
    done
}

ui_flow_stepper() {
    local current="$1" total="$2" index start end title marker_state label label_severity

    start=$((current - 1))
    end=$((current + 2))
    [ "$start" -lt 1 ] && start=1
    [ "$end" -gt "$total" ] && end="$total"
    printf '  '
    ui_color "$AIR_UI_COLOR_HEADER" "Where you are"
    printf '\n'
    if [ "$start" -gt 1 ]; then
        printf '    '
        ui_color "$AIR_UI_COLOR_MUTED" "... $((start - 1)) earlier step(s)"
        printf '\n'
    fi
    index="$start"
    while [ "$index" -le "$end" ]; do
        title="$(ui_flow_step_field "$index" TITLE)"
        if [ "$index" -lt "$current" ]; then
            marker_state="done"
            label="done"
            label_severity="ok"
        elif [ "$index" -eq "$current" ]; then
            marker_state="current"
            label="now"
            label_severity="hint"
        else
            marker_state="pending"
            label="next"
            label_severity="hint"
        fi
        printf '    '
        ui marker "$marker_state" --style bracket
        printf ' '
        ui_badge "$label" "$label_severity"
        printf ' %2s/%s ' "$index" "$total"
        if [ "$index" -eq "$current" ]; then
            ui_color "$AIR_UI_COLOR_TITLE" "${title:-step $index}"
        else
            printf '%s' "${title:-step $index}"
        fi
        printf '\n'
        index=$((index + 1))
    done
    if [ "$end" -lt "$total" ]; then
        printf '    '
        ui_color "$AIR_UI_COLOR_MUTED" "... $((total - end)) later step(s)"
        printf '\n'
    fi
}

ui_flow_intro() {
    ui title "${UI_FLOW_TITLE:-Air UI Flow}"
    printf '  '
    ui_text "${UI_FLOW_SUMMARY:-Run a guided Air UI flow.}"
    printf '\n  '
    ui_badge "${UI_FLOW_STEP_COUNT:-0} steps" hint
    printf '\n'
    ui spacer
    ui_flow_plan
}

ui_flow_use_wizard() {
    [ "${UI_FLOW_LAYOUT:-wizard}" = "wizard" ] || return 1
    ui_is_interactive || return 1
    ui_is_plain && return 1
    return 0
}

ui_flow_step_begin() {
    local index="$1" total="$2" title="$3" message="$4" type="${5:-}"

    ui_flow_step_layout "$index" "$total" "$title" "$message" "$type"
}

ui_flow_step_layout() {
    local index="$1" total="$2" title="$3" message="$4" type="${5:-}" log_file="${6:-}" next steps_file body_file

    next="$(ui_flow_step_field $((index + 1)) TITLE)"
    ui spacer
    steps_file="$(mktemp)"
    body_file="$(mktemp)"
    ui_flow_step_titles > "$steps_file"
    [ -n "$message" ] && ui_text "$message" > "$body_file"
    if ui_flow_use_wizard; then
        ui layout wizard \
            --current "$index" \
            --total "$total" \
            --title "${title:-step $index}" \
            --next "$next" \
            --kind "$type" \
            --rail "${UI_FLOW_LAYOUT_RAIL:-right}" \
            --body "$body_file" \
            --log "$log_file" \
            --log-height "${UI_FLOW_LAYOUT_LOG_HEIGHT:-8}" \
            --steps-file "$steps_file"
    else
        printf '  '
        ui_color "$AIR_UI_COLOR_HEADER" "Step $index/$total"
        [ -n "$type" ] && {
            printf ' '
            ui_badge "$type" hint
        }
        printf '\n  '
        ui marker current --style bare
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "${title:-step $index}"
        printf '\n'
        if [ -s "$body_file" ]; then
            printf '\n'
            ui_layout_indent_file 2 < "$body_file"
        fi
        [ -n "$next" ] && {
            printf '\n  '
            ui_color "$AIR_UI_COLOR_MUTED" "Next:"
            printf ' %s\n' "$next"
        }
        if [ -r "$log_file" ]; then
            printf '\n'
            ui layout viewport --title "Output" --height "${UI_FLOW_LAYOUT_LOG_HEIGHT:-8}" < "$log_file"
        fi
    fi
    rm -f "$steps_file" "$body_file"
}

ui_flow_run_task_action() {
    local action="$1" title="$2" task_log="$3"
    local pid status=0 frame frames frame_count index=1

    ui_flow_run_action "$action" >"$task_log" 2>&1 &
    pid="$!"

    if ui_can_animate; then
        frames="${AIR_UI_SPINNER_FRAMES:-◜ ◠ ◝ ◞ ◡ ◟}"
        frame_count="$(printf '%s\n' $frames | wc -l | awk '{print $1}')"
        [ "$frame_count" -gt 0 ] 2>/dev/null || frame_count=4
        while kill -0 "$pid" >/dev/null 2>&1; do
            frame="$(printf '%s\n' $frames | sed -n "${index}p")"
            [ -n "$frame" ] || frame="."
            printf '\r  ' >&2
            ui_color "$AIR_UI_COLOR_HINT" "$frame" >&2
            printf ' ' >&2
            ui_badge "running" hint >&2
            printf ' ' >&2
            ui_color "$AIR_UI_COLOR_TITLE" "$title" >&2
            sleep 0.12
            index=$((index + 1))
            [ "$index" -gt "$frame_count" ] && index=1
        done
        wait "$pid" || status="$?"
        printf '\r%*s\r' "$((${#title} + 18))" '' >&2
    else
        printf '  '
        ui_color "$AIR_UI_COLOR_HINT" "$(ui_icon loading)"
        printf ' '
        ui_badge "running" hint
        printf ' '
        ui_color "$AIR_UI_COLOR_TITLE" "$title"
        printf '\n'
        wait "$pid" || status="$?"
    fi

    return "$status"
}

ui_flow_select_from_lines() {
    local prompt="$1" default="$2" options="$3" style="$4"
    local option
    local -a args

    args=(--prompt "$prompt" --default "$default")
    [ -n "$style" ] && args+=(--style "$style")
    while IFS= read -r option; do
        [ -n "$option" ] && args+=(--option "$option")
    done <<EOF
$options
EOF
    ui select "${args[@]}"
}

ui_flow_action_parts() {
    local action="$1" file function_name

    case "$action" in
        *:*)
            file="${action%%:*}"
            function_name="${action##*:}"
            ;;
        *)
            return 1
            ;;
    esac

    case "$file" in
        ''|/*|*../*|../*|*'/..'|*'..')
            return 1
            ;;
    esac
    case "$function_name" in
        ''|*[^A-Za-z0-9_]*)
            return 1
            ;;
    esac

    UI_FLOW_ACTION_FILE="$UI_FLOW_DIR/$file"
    UI_FLOW_ACTION_FUNCTION="$function_name"
}

ui_flow_run_action() {
    local action="$1"
    local AIR_UI_FLOW_DIR="$UI_FLOW_DIR"
    local AIR_UI_FLOW_ID="$UI_FLOW_ID"

    ui_flow_action_parts "$action" || {
        ui check-item error "flow action" "Invalid action reference: $action"
        return 1
    }
    [ -r "$UI_FLOW_ACTION_FILE" ] || {
        ui check-item error "flow action" "Missing action file: $UI_FLOW_ACTION_FILE"
        return 1
    }

    # shellcheck disable=SC1090
    . "$UI_FLOW_ACTION_FILE" || return 1
    if ! declare -F "$UI_FLOW_ACTION_FUNCTION" >/dev/null 2>&1; then
        ui check-item error "flow action" "Missing action function: $UI_FLOW_ACTION_FUNCTION"
        return 1
    fi

    AIR_UI_FLOW_DIR="$AIR_UI_FLOW_DIR" AIR_UI_FLOW_ID="$AIR_UI_FLOW_ID" "$UI_FLOW_ACTION_FUNCTION"
}

ui_flow_export_result() {
    local id="$1" value="$2" var

    case "$id" in
        ''|*[^A-Za-z0-9_]*)
            return 0
            ;;
    esac
    var="AIR_UI_FLOW_RESULT_$id"
    printf -v "$var" '%s' "$value"
    export "$var"
}

ui_flow_run_step() {
    local index="$1" total="$2"
    local id type title message action required default risk options_action select_style value options status=0

    eval "id=\"\${UI_FLOW_STEP_${index}_ID:-}\""
    eval "type=\"\${UI_FLOW_STEP_${index}_TYPE:-info}\""
    eval "title=\"\${UI_FLOW_STEP_${index}_TITLE:-}\""
    eval "message=\"\${UI_FLOW_STEP_${index}_MESSAGE:-}\""
    eval "action=\"\${UI_FLOW_STEP_${index}_ACTION:-}\""
    eval "required=\"\${UI_FLOW_STEP_${index}_REQUIRED:-false}\""
    eval "default=\"\${UI_FLOW_STEP_${index}_DEFAULT:-}\""
    eval "risk=\"\${UI_FLOW_STEP_${index}_RISK:-medium}\""
    eval "options_action=\"\${UI_FLOW_STEP_${index}_OPTIONS_ACTION:-}\""
    eval "select_style=\"\${UI_FLOW_STEP_${index}_SELECT_STYLE:-}\""

    [ "$type" = "task" ] || ui_flow_step_begin "$index" "$total" "$title" "$message" "$type"
    case "$type" in
        info)
            [ -n "$message" ] && ui check-item hint "${title:-info}" "$message"
            ;;
        check)
            if [ -n "$action" ]; then
                ui_flow_run_action "$action" || status="$?"
                if [ "$status" != "0" ]; then
                    return "$status"
                fi
            else
                ui check-item error "${title:-check}" "Missing action."
                return 1
            fi
            ;;
        confirm)
            ui confirm \
                --title "${title:-Confirm}" \
                --message "$message" \
                --risk "$risk" \
                --default "${default:-no}" \
                --non-tty deny || return 1
            ui_flow_export_result "$id" yes
            ;;
        input)
            if [ "$required" = "true" ]; then
                value="$(ui input --prompt "${message:-$title}" --default "$default" --required)" || return 1
            else
                value="$(ui input --prompt "${message:-$title}" --default "$default")" || return 1
            fi
            ui_flow_export_result "$id" "$value"
            ui check-item ok "${title:-input}" "$value"
            ;;
        select)
            options=""
            if [ -n "$options_action" ]; then
                options="$(ui_flow_run_action "$options_action")" || return 1
            elif [ -n "$action" ]; then
                options="$(ui_flow_run_action "$action")" || return 1
            fi
            if [ -n "$options" ]; then
                value="$(ui_flow_select_from_lines "${message:-$title}" "$default" "$options" "$select_style")" || return 1
            else
                if [ -n "$select_style" ]; then
                    value="$(ui select --prompt "${message:-$title}" --default "$default" --style "$select_style")" || return 1
                else
                    value="$(ui select --prompt "${message:-$title}" --default "$default")" || return 1
                fi
            fi
            ui_flow_export_result "$id" "$value"
            ui check-item ok "${title:-select}" "$value"
            ;;
        task)
            local task_log task_status
            [ -n "$action" ] || {
                ui check-item error "${title:-task}" "Missing action."
                return 1
            }
            task_log="$(mktemp)"
            ui_flow_step_layout "$index" "$total" "$title" "$message" "$type"
            ui_flow_run_task_action "$action" "${title:-Task}" "$task_log"
            task_status="$?"
            ui_flow_step_layout "$index" "$total" "$title" "$message" "$type" "$task_log"
            if [ "$task_status" = "0" ]; then
                ui step ok "${title:-task}" "done"
            else
                ui step error "${title:-task}" "failed with status $task_status"
            fi
            rm -f "$task_log"
            return "$task_status"
            ;;
        preview)
            [ -n "$action" ] || {
                ui check-item error "${title:-preview}" "Missing action."
                return 1
            }
            ui_flow_run_action "$action"
            ;;
        stop)
            [ -n "$action" ] && ui_flow_run_action "$action"
            return 2
            ;;
        commit)
            [ -n "$action" ] || {
                ui check-item error "${title:-commit}" "Missing action."
                return 1
            }
            ui_flow_run_action "$action"
            ;;
        *)
            ui check-item error "flow step" "Unknown step type: $type"
            return 1
            ;;
    esac
}

ui_flow() {
    local file="${1:-}" index status=0

    [ -n "$file" ] || {
        ui check-item error "flow" "Missing flow TOML path."
        return 1
    }
    [ -r "$file" ] || {
        ui check-item error "flow" "Flow file is not readable: $file"
        return 1
    }

    ui_flow_parse "$file"
    ui_flow_intro

    index=1
    while [ "$index" -le "${UI_FLOW_STEP_COUNT:-0}" ]; do
        ui_flow_run_step "$index" "$UI_FLOW_STEP_COUNT" || {
            status="$?"
            if [ "$status" = "2" ]; then
                ui panel \
                    --title "Flow exited" \
                    --severity hint \
                    "${UI_FLOW_ID:-$file} exited before commit.

No state was changed."
                return 0
            fi
            ui panel \
                --title "Stopped before changes" \
                --severity blocked \
                "Stopped at step $index: $(ui_flow_step_field "$index" TITLE)

No state was written. Fix the blocked item above, then rerun the command."
            return "$status"
        }
        index=$((index + 1))
    done

    ui check-item ok "flow complete" "${UI_FLOW_ID:-$file}"
}

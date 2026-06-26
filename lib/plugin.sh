# Plugin protocol helpers.

plugin_dir() {
    printf '%s\n' "$AIR_HOME/plugins/$1"
}

plugin_data_dir() {
    printf '%s\n' "${AIR_STATE_HOME:-$AIR_HOME/state}/plugins/$1"
}

plugin_meta_path() {
    printf '%s\n' "$(plugin_dir "$1")/plugin.toml"
}

plugin_settings_path() {
    printf '%s\n' "$(plugin_data_dir "$1")/settings.sh"
}

plugin_state_path() {
    printf '%s\n' "$(plugin_data_dir "$1")/state.sh"
}

plugin_setup_path() {
    printf '%s\n' "$(plugin_data_dir "$1")/setup"
}

plugin_enabled_path() {
    printf '%s\n' "$(plugin_data_dir "$1")/enabled"
}

plugin_exists() {
    [ -r "$(plugin_meta_path "$1")" ]
}

plugin_names() {
    local dir

    [ -d "$AIR_HOME/plugins" ] || return 0
    for dir in "$AIR_HOME"/plugins/*; do
        [ -d "$dir" ] || continue
        [ -r "$dir/plugin.toml" ] || continue
        printf '%s\n' "${dir##*/}"
    done
}

plugin_meta_value() {
    local plugin="$1"
    local key="$2"
    local meta line value section="" wanted_section="" wanted_key="$key"

    meta="$(plugin_meta_path "$plugin")"
    [ -r "$meta" ] || return 1

    case "$key" in
        *.*)
            wanted_section="${key%.*}"
            wanted_key="${key##*.}"
            ;;
    esac

    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"
        case "$line" in
            \[*\])
                section="${line#[}"
                section="${section%]}"
                continue
                ;;
        esac
        [ "$section" = "$wanted_section" ] || continue
        case "$line" in
            "$wanted_key"\ =*)
                value="${line#*=}"
                value="${value#"${value%%[![:space:]]*}"}"
                value="${value%,}"
                value="${value%\"}"
                value="${value#\"}"
                printf '%s\n' "$value"
                return 0
                ;;
        esac
    done < "$meta"

    return 1
}

plugin_meta_array() {
    local plugin="$1"
    local key="$2"
    local meta line section="" wanted_section="" wanted_key="$key" collecting=0 value

    meta="$(plugin_meta_path "$plugin")"
    [ -r "$meta" ] || return 1

    case "$key" in
        *.*)
            wanted_section="${key%.*}"
            wanted_key="${key##*.}"
            ;;
    esac

    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"

        if [ "$collecting" = "1" ]; then
            case "$line" in
                \]*) return 0 ;;
                \"*\"*|\'*\'*)
                    value="${line%,}"
                    value="${value%\"}"
                    value="${value#\"}"
                    value="${value%\'}"
                    value="${value#\'}"
                    [ -n "$value" ] && printf '%s\n' "$value"
                    ;;
            esac
            continue
        fi

        case "$line" in
            \[*\])
                section="${line#[}"
                section="${section%]}"
                continue
                ;;
        esac

        [ "$section" = "$wanted_section" ] || continue
        case "$line" in
            "$wanted_key"\ =\ \[*)
                value="${line#*=}"
                value="${value#"${value%%[![:space:]]*}"}"
                case "$value" in
                    \[\])
                        return 0
                        ;;
                    \[*\])
                        value="${value#[}"
                        value="${value%]}"
                        value="${value//,/ }"
                        for value in $value; do
                            value="${value%\"}"
                            value="${value#\"}"
                            value="${value%\'}"
                            value="${value#\'}"
                            [ -n "$value" ] && printf '%s\n' "$value"
                        done
                        return 0
                        ;;
                    \[*)
                        collecting=1
                        ;;
                esac
                ;;
        esac
    done < "$meta"

    [ "$collecting" = "1" ]
}

plugin_toml_value() {
    local file="$1"
    local key="$2"
    local line value section="" wanted_section="" wanted_key="$key"

    [ -r "$file" ] || return 1
    case "$key" in
        *.*)
            wanted_section="${key%.*}"
            wanted_key="${key##*.}"
            ;;
    esac

    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"
        case "$line" in
            \[*\])
                section="${line#[}"
                section="${section%]}"
                continue
                ;;
        esac
        [ "$section" = "$wanted_section" ] || continue
        case "$line" in
            "$wanted_key"\ =*)
                value="${line#*=}"
                value="${value#"${value%%[![:space:]]*}"}"
                value="${value%,}"
                value="${value%\"}"
                value="${value#\"}"
                printf '%s\n' "$value"
                return 0
                ;;
        esac
    done < "$file"

    return 1
}

plugin_function_token() {
    printf '%s' "$1" | tr -c 'A-Za-z0-9_' '_'
}

plugin_is_enabled() {
    [ -f "$(plugin_enabled_path "$1")" ]
}

plugin_is_setup() {
    [ -f "$(plugin_setup_path "$1")" ]
}

enable_plugin_state() {
    local plugin="$1"

    mkdir -p "$(plugin_data_dir "$plugin")"
    printf 'enabled\n' > "$(plugin_enabled_path "$plugin")"
}

disable_plugin_state() {
    rm -f "$(plugin_enabled_path "$1")"
}

mark_plugin_setup() {
    local plugin="$1"

    mkdir -p "$(plugin_data_dir "$plugin")"
    printf 'setup\n' > "$(plugin_setup_path "$plugin")"
}

clear_plugin_setup() {
    rm -f "$(plugin_setup_path "$1")"
}

enabled_plugins() {
    local plugin

    for plugin in $(plugin_names); do
        plugin_is_enabled "$plugin" && printf '%s\n' "$plugin"
    done
}

plugin_src_dir() {
    printf '%s\n' "$(plugin_dir "$1")/src"
}

plugin_src_lib_dir() {
    printf '%s\n' "$(plugin_src_dir "$1")/lib"
}

plugin_commands_meta_path() {
    printf '%s\n' "$(plugin_dir "$1")/commands.toml"
}

source_plugin() {
    local plugin="$1"
    local part

    plugin_exists "$plugin" || return 1
    for part in "$(plugin_src_lib_dir "$plugin")"/*.sh; do
        [ -r "$part" ] && . "$part"
    done
    for part in "$(plugin_src_dir "$plugin")/state.sh"; do
        [ -r "$part" ] && . "$part"
    done

    return 0
}

plugin_lifecycle_path() {
    local plugin="$1" lifecycle

    lifecycle="$(plugin_meta_value "$plugin" entry.lifecycle 2>/dev/null || true)"
    if [ -n "$lifecycle" ]; then
        printf '%s\n' "$(plugin_dir "$plugin")/$lifecycle"
    else
        printf '%s\n' "$(plugin_dir "$plugin")/lifecycle.sh"
    fi
}

plugin_runtime_path() {
    local plugin="$1" runtime

    runtime="$(plugin_meta_value "$plugin" entry.runtime 2>/dev/null || true)"
    if [ -n "$runtime" ]; then
        printf '%s\n' "$(plugin_dir "$plugin")/$runtime"
    else
        printf '%s\n' "$(plugin_dir "$plugin")/runtime.sh"
    fi
}

plugin_command_path() {
    local plugin="$1" command

    command="$(plugin_meta_value "$plugin" entry.commands 2>/dev/null || true)"
    if [ -n "$command" ]; then
        printf '%s\n' "$(plugin_dir "$plugin")/$command"
    else
        printf '%s\n' "$(plugin_src_dir "$plugin")/commands.sh"
    fi
}

plugin_default_settings_path() {
    local plugin="$1" settings

    settings="$(plugin_meta_value "$plugin" entry.settings 2>/dev/null || true)"
    if [ -n "$settings" ]; then
        printf '%s\n' "$(plugin_dir "$plugin")/$settings"
    else
        printf '%s\n' "$(plugin_dir "$plugin")/settings.sh"
    fi
}

plugin_ensure_settings() {
    local plugin="$1"
    local settings default_settings

    plugin_exists "$plugin" || return 1
    settings="$(plugin_settings_path "$plugin")"
    default_settings="$(plugin_default_settings_path "$plugin")"

    mkdir -p "$(plugin_data_dir "$plugin")"
    if [ ! -e "$settings" ] && [ -r "$default_settings" ]; then
        cp "$default_settings" "$settings"
    fi
}

plugin_ensure_template() {
    local plugin="$1" template="$2" target="$3" source

    plugin_exists "$plugin" || return 1
    source="$(plugin_dir "$plugin")/$template"
    [ -r "$source" ] || return 1
    mkdir -p "$(dirname "$target")"
    if [ ! -e "$target" ]; then
        cp "$source" "$target"
    fi
}

plugin_command_meta_value() {
    local plugin="$1" key="$2"

    plugin_toml_value "$(plugin_commands_meta_path "$plugin")" "$key"
}

plugin_command_rows() {
    local plugin="$1" file line section="" name="" usage="" summary="" handler="" aliases="" group=""

    file="$(plugin_commands_meta_path "$plugin")"
    [ -r "$file" ] || return 1
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"
        case "$line" in
            '[[commands]]'|'[[groups.commands]]'|'[[groups]]')
                if [ -n "$name" ]; then
                    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${group:--}" "$name" "$usage" "$summary" "$handler" "$aliases"
                fi
                section="$line"
                name="" usage="" summary="" handler="" aliases="" group=""
                continue
                ;;
            \[*)
                continue
                ;;
        esac
        case "$section" in
            '[[commands]]'|'[[groups.commands]]') ;;
            *) continue ;;
        esac
        case "$line" in
            name\ =*)
                name="${line#*=}"
                name="${name#"${name%%[![:space:]]*}"}"
                name="${name%\"}"
                name="${name#\"}"
                ;;
            usage\ =*)
                usage="${line#*=}"
                usage="${usage#"${usage%%[![:space:]]*}"}"
                usage="${usage%\"}"
                usage="${usage#\"}"
                ;;
            summary\ =*)
                summary="${line#*=}"
                summary="${summary#"${summary%%[![:space:]]*}"}"
                summary="${summary%\"}"
                summary="${summary#\"}"
                ;;
            handler\ =*)
                handler="${line#*=}"
                handler="${handler#"${handler%%[![:space:]]*}"}"
                handler="${handler%\"}"
                handler="${handler#\"}"
                ;;
            group\ =*)
                group="${line#*=}"
                group="${group#"${group%%[![:space:]]*}"}"
                group="${group%\"}"
                group="${group#\"}"
                ;;
            aliases\ =*)
                aliases="${line#*=}"
                aliases="${aliases#"${aliases%%[![:space:]]*}"}"
                aliases="${aliases#[}"
                aliases="${aliases%]}"
                aliases="${aliases//\"/}"
                aliases="${aliases//,/ }"
                ;;
        esac
    done < "$file"

    if [ -n "$name" ]; then
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${group:--}" "$name" "$usage" "$summary" "$handler" "$aliases"
    fi
}

plugin_command_group_title() {
    local plugin="$1" group="$2" file line in_group=0 name="" title="" wanted="$group"

    file="$(plugin_commands_meta_path "$plugin")"
    [ -r "$file" ] || return 1
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"
        case "$line" in
            '[[groups]]')
                in_group=1
                name="" title=""
                continue
                ;;
            '[[commands]]'|'[[groups.commands]]'|\[*)
                if [ "$in_group" = "1" ] && [ "$name" = "$wanted" ]; then
                    printf '%s\n' "$title"
                    return 0
                fi
                in_group=0
                continue
                ;;
        esac
        [ "$in_group" = "1" ] || continue
        case "$line" in
            name\ =*)
                name="${line#*=}"
                name="${name#"${name%%[![:space:]]*}"}"
                name="${name%\"}"
                name="${name#\"}"
                ;;
            title\ =*)
                title="${line#*=}"
                title="${title#"${title%%[![:space:]]*}"}"
                title="${title%\"}"
                title="${title#\"}"
                ;;
        esac
    done < "$file"

    if [ "$in_group" = "1" ] && [ "$name" = "$wanted" ]; then
        printf '%s\n' "$title"
        return 0
    fi
    return 1
}

plugin_command_help_for_group() {
    local plugin="$1" group="${2:-}" title row row_group name usage summary handler aliases

    if [ -n "$group" ]; then
        title="$(plugin_command_group_title "$plugin" "$group" 2>/dev/null || printf 'air %s %s' "$(plugin_command_name "$plugin")" "$group")"
    else
        title="$(plugin_command_meta_value "$plugin" title 2>/dev/null || printf 'air %s' "$(plugin_command_name "$plugin")")"
    fi

    printf '%s\n\n' "$title"
    printf '用法:\n'
    plugin_command_rows "$plugin" | while IFS="$(printf '\t')" read -r row_group name usage summary handler aliases; do
        [ "$row_group" = "${group:--}" ] || continue
        [ -n "$usage" ] || usage="air $(plugin_command_name "$plugin") $name"
        printf '  %s\n' "$usage"
    done
    printf '\n命令:\n'
    plugin_command_rows "$plugin" | while IFS="$(printf '\t')" read -r row_group name usage summary handler aliases; do
        [ "$row_group" = "${group:--}" ] || continue
        printf '  %-12s %s\n' "$name" "$summary"
    done
}

plugin_command_handler_for() {
    local plugin="$1" group="$2" requested="$3" row_group name usage summary handler aliases alias

    plugin_command_rows "$plugin" | while IFS="$(printf '\t')" read -r row_group name usage summary handler aliases; do
        [ "$row_group" = "${group:--}" ] || continue
        if [ "$name" = "$requested" ]; then
            printf '%s\n' "$handler"
            return 0
        fi
        for alias in $aliases; do
            if [ "$alias" = "$requested" ]; then
                printf '%s\n' "$handler"
                return 0
            fi
        done
    done | sed -n '1p'
}

plugin_dispatch_command() {
    local plugin="$1" group="" command handler

    shift
    command="${1:-}"
    case "$command" in
        -h|--help|'')
            plugin_command_help_for_group "$plugin" ""
            return 0
            ;;
    esac

    handler="$(plugin_command_handler_for "$plugin" "" "$command")"
    if [ -z "$handler" ]; then
        log_error "air $(plugin_command_name "$plugin"): 未知命令: $command"
        log_warn "运行 air $(plugin_command_name "$plugin") --help 查看用法。"
        return 1
    fi

    if ! declare -F "$handler" >/dev/null 2>&1; then
        log_error "插件 $plugin 命令缺少 handler: $handler"
        return 1
    fi

    shift
    "$handler" "$@"
}

plugin_dispatch_group_command() {
    local plugin="$1" group="$2" command handler

    shift 2
    command="${1:-}"
    case "$command" in
        -h|--help|'')
            plugin_command_help_for_group "$plugin" "$group"
            return 0
            ;;
    esac

    handler="$(plugin_command_handler_for "$plugin" "$group" "$command")"
    if [ -z "$handler" ]; then
        log_error "air $(plugin_command_name "$plugin") $group: 未知命令: $command"
        log_warn "运行 air $(plugin_command_name "$plugin") $group --help 查看用法。"
        return 1
    fi
    if ! declare -F "$handler" >/dev/null 2>&1; then
        log_error "插件 $plugin 命令缺少 handler: $handler"
        return 1
    fi
    shift
    "$handler" "$@"
}

plugin_call() {
    local plugin="$1"
    local action="$2"
    local script function_name invoke_function token status
    local core_function_def plugin_function_def
    local AIR_PLUGIN AIR_PLUGIN_DIR AIR_PLUGIN_DATA_DIR

    shift 2
    plugin_exists "$plugin" || {
        log_error "未知插件: $plugin"
        return 1
    }

    source_plugin "$plugin" || return 1
    script="$(plugin_lifecycle_path "$plugin" "$action")"
    if [ ! -r "$script" ]; then
        log_error "插件 $plugin 不支持操作: $action"
        return 1
    fi

    function_name="plugin_$action"
    token="$(plugin_function_token "$plugin")"
    invoke_function="__air_${token}_${action}"
    core_function_def="$(declare -f "$function_name" 2>/dev/null || true)"

    AIR_PLUGIN="$plugin"
    AIR_PLUGIN_DIR="$(plugin_dir "$plugin")"
    AIR_PLUGIN_DATA_DIR="$(plugin_data_dir "$plugin")"
    export AIR_PLUGIN AIR_PLUGIN_DIR AIR_PLUGIN_DATA_DIR

    . "$script"
    if ! declare -F "$function_name" >/dev/null 2>&1; then
        log_error "插件 $plugin 的生命周期脚本缺少函数: plugin_$action"
        [ -n "$core_function_def" ] && eval "$core_function_def"
        return 1
    fi

    plugin_function_def="$(declare -f "$function_name")"
    eval "$invoke_function() $(printf '%s\n' "$plugin_function_def" | sed '1d')"
    if [ -n "$core_function_def" ]; then
        eval "$core_function_def"
    else
        unset -f "$function_name" 2>/dev/null || true
    fi

    if ! declare -F "$invoke_function" >/dev/null 2>&1; then
        [ -n "$core_function_def" ] && eval "$core_function_def"
        return 1
    fi

    status=0
    "$invoke_function" "$@" || status="$?"
    unset -f "$invoke_function"
    return "$status"
}

plugin_action_path() {
    printf '%s\n' "$(plugin_src_dir "$1")/actions/$2.sh"
}

plugin_run_action() {
    local plugin="$1"
    local event="$2"
    local action="$3"
    local script function_name status
    local AIR_PLUGIN AIR_EVENT AIR_ACTION AIR_PLUGIN_DIR AIR_PLUGIN_DATA_DIR

    script="$(plugin_action_path "$plugin" "$action")"
    [ -r "$script" ] || {
        log warn "插件 $plugin 的 action 文件不存在: $action"
        return 1
    }

    source_plugin "$plugin" || return 1
    function_name="action_$action"
    function_name="$(printf '%s' "$function_name" | tr -c 'A-Za-z0-9_' '_')"
    unset -f "$function_name" 2>/dev/null || true

    AIR_PLUGIN="$plugin"
    AIR_EVENT="$event"
    AIR_ACTION="$action"
    AIR_PLUGIN_DIR="$(plugin_dir "$plugin")"
    AIR_PLUGIN_DATA_DIR="$(plugin_data_dir "$plugin")"
    export AIR_PLUGIN AIR_EVENT AIR_ACTION AIR_PLUGIN_DIR AIR_PLUGIN_DATA_DIR

    . "$script"
    if ! declare -F "$function_name" >/dev/null 2>&1; then
        log warn "插件 $plugin 的 action 缺少函数: $function_name"
        return 1
    fi

    status=0
    "$function_name" || status="$?"
    unset -f "$function_name"
    return "$status"
}

plugin_run_actions() {
    local plugin="$1"
    local event="$2"
    local action status=0

    while IFS= read -r action; do
        [ -n "$action" ] || continue
        plugin_run_action "$plugin" "$event" "$action" || status="$?"
    done <<EOF
$(plugin_meta_array "$plugin" "events.$event" 2>/dev/null || true)
EOF

    return "$status"
}

plugin_setup_risk() {
    plugin_meta_value "$1" setup.risk 2>/dev/null || printf 'medium\n'
}

plugin_setup_summary() {
    plugin_meta_value "$1" setup.summary 2>/dev/null || printf 'Prepare plugin runtime resources.\n'
}

plugin_confirm_setup() {
    local plugin="$1"
    local risk summary

    risk="$(plugin_setup_risk "$plugin")"
    summary="$(plugin_setup_summary "$plugin")"
    ui confirm \
        --title "Setup required: $plugin" \
        --message "$summary" \
        --risk "$risk" \
        --default "$(ui_risk_default "$risk")" \
        --non-tty deny
}

plugin_confirm_reset() {
    local plugin="$1"

    ui confirm \
        --title "Reset plugin: $plugin" \
        --message "This will remove plugin runtime resources and local plugin state." \
        --risk destructive \
        --default no \
        --non-tty deny
}

plugin_confirm_disable_for_reset() {
    local plugin="$1"

    ui confirm \
        --title "Disable before reset: $plugin" \
        --message "The plugin is currently enabled and must be disabled before reset." \
        --risk high \
        --default no \
        --non-tty deny
}

plugin_setup() {
    local plugin="$1"

    plugin_is_setup "$plugin" && return 0

    plugin_call "$plugin" setup || return 1
    mark_plugin_setup "$plugin"
}

plugin_enable() {
    local plugin="$1"

    plugin_can_enable "$plugin" || return 1

    if ! plugin_is_setup "$plugin"; then
        plugin_confirm_setup "$plugin" || {
            log warn "已取消启用插件: $plugin"
            return 1
        }
        plugin_setup "$plugin" || return 1
    fi

    plugin_call "$plugin" enable || return 1
    enable_plugin_state "$plugin"
}

plugin_disable() {
    local plugin="$1"

    plugin_call "$plugin" disable || return 1
    disable_plugin_state "$plugin"
    plugin_run_actions "$plugin" after_disable || true
}

plugin_reset() {
    local plugin="$1"

    if plugin_is_enabled "$plugin"; then
        plugin_confirm_disable_for_reset "$plugin" || {
            log warn "已取消重置插件: $plugin"
            return 1
        }
        plugin_disable "$plugin" || return 1
    fi

    plugin_confirm_reset "$plugin" || {
        log warn "已取消重置插件: $plugin"
        return 1
    }

    plugin_call "$plugin" reset || return 1
    disable_plugin_state "$plugin"
    clear_plugin_setup "$plugin"
}

plugin_init() {
    local plugin="$1"
    local script function_name status shell

    shift
    plugin_exists "$plugin" || return 0
    plugin_is_enabled "$plugin" || return 0
    plugin_check_contract "$plugin" --quiet || return 0
    if ! plugin_is_setup "$plugin"; then
        log warn "插件 $plugin 已启用但尚未 setup；请运行 air enable $plugin。"
        return 0
    fi

    script="$(plugin_runtime_path "$plugin")"
    [ -r "$script" ] || return 0
    source_plugin "$plugin" >/dev/null 2>&1 || return 0

    function_name="runtime_init"
    unset -f "$function_name" 2>/dev/null || true
    . "$script" >/dev/null 2>&1 || return 0
    if ! declare -F "$function_name" >/dev/null 2>&1; then
        log warn "插件 $plugin 的 runtime 缺少函数: $function_name"
        return 0
    fi

    shell="${1:-bash}"
    status=0
    "$function_name" "$shell" >/dev/null 2>&1 || status="$?"
    unset -f "$function_name"
    [ "$status" = "0" ] || return 0
    return 0
}

plugin_status() {
    local plugin="$1"
    local script function_name invoke_function token status
    local core_function_def plugin_function_def
    local AIR_PLUGIN AIR_PLUGIN_DIR AIR_PLUGIN_DATA_DIR

    if ! plugin_exists "$plugin"; then
        ui kv "插件" "$plugin"
        ui kv "状态" "unknown"
        return 0
    fi

    script="$(plugin_lifecycle_path "$plugin" status)"
    if [ ! -r "$script" ]; then
        ui kv "插件" "$plugin"
        ui kv "状态" "$(plugin_is_enabled "$plugin" && printf enabled || printf disabled)"
        ui kv "Setup" "$(plugin_is_setup "$plugin" && printf ready || printf missing)"
        return 0
    fi

    source_plugin "$plugin" || return 1
    function_name="plugin_status"
    token="$(plugin_function_token "$plugin")"
    invoke_function="__air_${token}_status"
    core_function_def="$(declare -f "$function_name" 2>/dev/null || true)"

    AIR_PLUGIN="$plugin"
    AIR_PLUGIN_DIR="$(plugin_dir "$plugin")"
    AIR_PLUGIN_DATA_DIR="$(plugin_data_dir "$plugin")"
    export AIR_PLUGIN AIR_PLUGIN_DIR AIR_PLUGIN_DATA_DIR

    . "$script"
    if ! declare -F "$function_name" >/dev/null 2>&1; then
        log error "插件 $plugin 的 status 脚本缺少函数: plugin_status"
        [ -n "$core_function_def" ] && eval "$core_function_def"
        return 1
    fi

    plugin_function_def="$(declare -f "$function_name")"
    eval "$invoke_function() $(printf '%s\n' "$plugin_function_def" | sed '1d')"
    if [ -n "$core_function_def" ]; then
        eval "$core_function_def"
    else
        unset -f "$function_name" 2>/dev/null || true
    fi

    status=0
    "$invoke_function" || status="$?"
    unset -f "$invoke_function"
    return "$status"
}

plugin_run_command() {
    local plugin="$1"
    local command_file
    local AIR_PLUGIN AIR_PLUGIN_DIR AIR_PLUGIN_DATA_DIR

    shift
    command_file="$(plugin_command_path "$plugin")"
    [ -r "$command_file" ] || {
        log_error "插件没有命令入口: $plugin"
        return 1
    }

    AIR_PLUGIN="$plugin"
    AIR_PLUGIN_DIR="$(plugin_dir "$plugin")"
    AIR_PLUGIN_DATA_DIR="$(plugin_data_dir "$plugin")"
    export AIR_PLUGIN AIR_PLUGIN_DIR AIR_PLUGIN_DATA_DIR

    source_plugin "$plugin" || return 1
    . "$command_file"
    plugin_dispatch_command "$plugin" "$@"
}

plugin_command_name() {
    plugin_meta_value "$1" command 2>/dev/null
}

plugin_for_command() {
    local requested="$1" plugin command

    for plugin in $(plugin_names); do
        command="$(plugin_command_name "$plugin" || true)"
        [ "$command" = "$requested" ] || continue
        printf '%s\n' "$plugin"
        return 0
    done

    return 1
}

plugin_command_help() {
    local plugin command description

    for plugin in $(plugin_names); do
        command="$(plugin_command_name "$plugin" || true)"
        [ -n "$command" ] || continue
        description="$(plugin_meta_value "$plugin" description 2>/dev/null || printf '-')"
        printf '  %-9s %s\n' "$command" "$description"
    done
}

plugin_structure_health() {
    local plugin="$1" status="ok"

    [ -r "$(plugin_meta_path "$plugin")" ] || status="broken"
    [ -r "$(plugin_commands_meta_path "$plugin")" ] || status="partial"
    [ -d "$(plugin_src_dir "$plugin")" ] || status="partial"
    [ -r "$(plugin_command_path "$plugin")" ] || status="partial"
    [ -r "$(plugin_runtime_path "$plugin")" ] || status="partial"
    [ -r "$(plugin_lifecycle_path "$plugin" status)" ] || status="partial"
    [ -r "$(plugin_default_settings_path "$plugin")" ] || status="partial"
    printf '%s\n' "$status"
}

plugin_check_reset_counts() {
    AIR_PLUGIN_CHECK_ERRORS=0
    AIR_PLUGIN_CHECK_WARNINGS=0
    AIR_PLUGIN_CHECK_QUIET="${AIR_PLUGIN_CHECK_QUIET:-0}"
}

plugin_check_issue() {
    local severity="$1" title="$2" message="$3"

    case "$severity" in
        error|blocked)
            AIR_PLUGIN_CHECK_ERRORS=$((AIR_PLUGIN_CHECK_ERRORS + 1))
            ;;
        warning|warn)
            AIR_PLUGIN_CHECK_WARNINGS=$((AIR_PLUGIN_CHECK_WARNINGS + 1))
            ;;
    esac

    [ "${AIR_PLUGIN_CHECK_QUIET:-0}" = "1" ] && return 0
    ui check-item "$severity" "$title" "$message"
}

plugin_check_file() {
    local label="$1" file="$2" required="${3:-1}"

    if [ -r "$file" ] || [ -d "$file" ]; then
        [ "${AIR_PLUGIN_CHECK_QUIET:-0}" = "1" ] || ui check-item ok "$label" "$file"
        return 0
    fi

    if [ "$required" = "1" ]; then
        plugin_check_issue error "$label" "Missing required path: $file"
    else
        plugin_check_issue warning "$label" "Missing optional path: $file"
    fi
}

plugin_check_shell_syntax() {
    local file="$1" output

    [ -r "$file" ] || return 0
    output="$(bash -n "$file" 2>&1)" || {
        plugin_check_issue error "syntax" "$file: $output"
        return 1
    }
    [ "${AIR_PLUGIN_CHECK_QUIET:-0}" = "1" ] || ui check-item ok "syntax" "$file"
}

plugin_lifecycle_defines_function() {
    local plugin="$1" function_name="$2" script

    script="$(plugin_lifecycle_path "$plugin" setup)"
    [ -r "$script" ] || return 1
    grep -Eq "^[[:space:]]*(function[[:space:]]+)?${function_name}([[:space:]]*\\(\\))?[[:space:]]*\\{" "$script"
}

plugin_run_preflight() {
    local plugin="$1" purpose="${2:-enable}" function_name="" script

    if plugin_lifecycle_defines_function "$plugin" plugin_preflight; then
        function_name="plugin_preflight"
    elif plugin_lifecycle_defines_function "$plugin" plugin_check; then
        function_name="plugin_check"
    else
        return 0
    fi

    script="$(plugin_lifecycle_path "$plugin" setup)"
    (
        AIR_PLUGIN="$plugin"
        AIR_PLUGIN_DIR="$(plugin_dir "$plugin")"
        AIR_PLUGIN_DATA_DIR="$(plugin_data_dir "$plugin")"
        export AIR_PLUGIN AIR_PLUGIN_DIR AIR_PLUGIN_DATA_DIR

        source_plugin "$plugin" || exit 1
        . "$script" || exit 1
        declare -F "$function_name" >/dev/null 2>&1 || exit 0
        "$function_name" "$purpose"
    )
}

plugin_check_contract() {
    local plugin="$1" quiet="${2:-}" status=0 file row_group command usage summary handler aliases action command_file

    AIR_PLUGIN_CHECK_QUIET=0
    [ "$quiet" = "--quiet" ] && AIR_PLUGIN_CHECK_QUIET=1
    plugin_check_reset_counts

    if ! plugin_exists "$plugin"; then
        plugin_check_issue error "plugin" "Unknown plugin: $plugin"
        return 1
    fi

    [ "$AIR_PLUGIN_CHECK_QUIET" = "1" ] || {
        ui kv "插件" "$plugin"
        ui kv "目录" "$(plugin_dir "$plugin")"
        ui kv "结构" "$(plugin_structure_health "$plugin")"
    }

    plugin_check_file "plugin.toml" "$(plugin_meta_path "$plugin")" 1
    plugin_check_file "commands.toml" "$(plugin_commands_meta_path "$plugin")" 1
    plugin_check_file "src" "$(plugin_src_dir "$plugin")" 1
    plugin_check_file "commands" "$(plugin_command_path "$plugin")" 1
    plugin_check_file "runtime" "$(plugin_runtime_path "$plugin")" 1
    plugin_check_file "lifecycle" "$(plugin_lifecycle_path "$plugin" setup)" 1
    plugin_check_file "settings" "$(plugin_default_settings_path "$plugin")" 1

    plugin_check_shell_syntax "$(plugin_command_path "$plugin")"
    plugin_check_shell_syntax "$(plugin_runtime_path "$plugin")"
    plugin_check_shell_syntax "$(plugin_lifecycle_path "$plugin" setup)"
    plugin_check_shell_syntax "$(plugin_default_settings_path "$plugin")"
    if [ -d "$(plugin_src_dir "$plugin")" ]; then
        while IFS= read -r file; do
            plugin_check_shell_syntax "$file"
        done <<EOF
$(find "$(plugin_src_dir "$plugin")" -type f \( -name '*.sh' -o -name '*.bash' \) 2>/dev/null | sort)
EOF
    fi

    command_file="$(plugin_command_path "$plugin")"
    if [ -r "$command_file" ] && [ -r "$(plugin_commands_meta_path "$plugin")" ]; then
        source_plugin "$plugin" || plugin_check_issue error "source" "Failed to source plugin state: $plugin"
        . "$command_file"
        while IFS="$(printf '\t')" read -r row_group command usage summary handler aliases; do
            [ -n "$command" ] || continue
            if declare -F "$handler" >/dev/null 2>&1; then
                [ "$AIR_PLUGIN_CHECK_QUIET" = "1" ] || {
                    [ "$row_group" = "-" ] && row_group=""
                    ui check-item ok "cmd ${row_group:+$row_group/}$command" "$handler"
                }
            else
                [ "$row_group" = "-" ] && row_group=""
                plugin_check_issue error "cmd ${row_group:+$row_group/}$command" "Missing handler: $handler"
            fi
        done <<EOF
$(plugin_command_rows "$plugin")
EOF
    fi

    while IFS= read -r action; do
        [ -n "$action" ] || continue
        if [ -r "$(plugin_action_path "$plugin" "$action")" ]; then
            [ "$AIR_PLUGIN_CHECK_QUIET" = "1" ] || ui check-item ok "action $action" "$(plugin_action_path "$plugin" "$action")"
        else
            plugin_check_issue error "action $action" "Missing action file: $(plugin_action_path "$plugin" "$action")"
        fi
    done <<EOF
$(plugin_meta_array "$plugin" events.after_disable 2>/dev/null || true)
EOF

    [ "$AIR_PLUGIN_CHECK_ERRORS" -eq 0 ] || status=1
    if [ "$AIR_PLUGIN_CHECK_QUIET" != "1" ]; then
        if [ "$AIR_PLUGIN_CHECK_ERRORS" -eq 0 ] && [ "$AIR_PLUGIN_CHECK_WARNINGS" -eq 0 ]; then
            ui check-item ok "contract summary" "No errors or warnings."
        elif [ "$AIR_PLUGIN_CHECK_ERRORS" -eq 0 ]; then
            ui check-item warning "contract summary" "$AIR_PLUGIN_CHECK_WARNINGS warning(s), no errors."
        else
            ui check-item error "contract summary" "$AIR_PLUGIN_CHECK_ERRORS error(s), $AIR_PLUGIN_CHECK_WARNINGS warning(s)."
        fi
    fi
    return "$status"
}

plugin_can_enable() {
    local plugin="$1" errors warnings

    plugin_check_contract "$plugin" --quiet
    errors="$AIR_PLUGIN_CHECK_ERRORS"
    warnings="$AIR_PLUGIN_CHECK_WARNINGS"

    if [ "$errors" -gt 0 ]; then
        plugin_check_contract "$plugin"
        ui check-item blocked "Cannot enable plugin" "$plugin has contract errors."
        return 1
    fi

    if [ "$warnings" -gt 0 ]; then
        plugin_check_contract "$plugin"
        ui confirm \
            --title "Plugin has warnings: $plugin" \
            --message "Enable anyway?" \
            --risk medium \
            --default no \
            --non-tty deny || return 1
    fi

    if ! plugin_run_preflight "$plugin" enable; then
        ui check-item blocked "Cannot enable plugin" "$plugin preflight failed."
        return 1
    fi
}

plugin_check() {
    local plugin="$1" status=0

    plugin_check_contract "$plugin" || status="$?"
    if plugin_lifecycle_defines_function "$plugin" plugin_preflight || plugin_lifecycle_defines_function "$plugin" plugin_check; then
        if plugin_run_preflight "$plugin" check; then
            ui check-item ok "preflight" "Plugin-specific preflight passed."
        else
            ui check-item error "preflight" "Plugin-specific preflight failed."
            status=1
        fi
    else
        ui check-item hint "preflight" "No plugin-specific preflight declared."
    fi
    return "$status"
}

plugin_scaffold() {
    local plugin="$1" dir token

    case "$plugin" in
        ''|.*|*/*|*[^A-Za-z0-9._-]*)
            log_error "air plugin scaffold: 无效插件名: $plugin"
            return 1
            ;;
    esac

    dir="$(plugin_dir "$plugin")"
    token="$(plugin_function_token "$plugin")"
    if [ -e "$dir" ]; then
        log_error "air plugin scaffold: 插件已存在: $plugin"
        return 1
    fi

    mkdir -p "$dir/src/lib" "$dir/src/actions" "$dir/tests"
    cat > "$dir/plugin.toml" <<EOF
schema = "air.plugin/v1"
id = "$plugin"
name = "$plugin"
version = "0.1.0"
description = "$plugin plugin"
command = "$plugin"

[entry]
commands = "src/commands.sh"
runtime = "runtime.sh"
lifecycle = "lifecycle.sh"
settings = "settings.sh"

[setup]
risk = "medium"
summary = "Prepare $plugin plugin runtime resources."
EOF
    cat > "$dir/commands.toml" <<EOF
title = "air $plugin - $plugin plugin"
summary = "$plugin plugin"

[[commands]]
name = "status"
usage = "air $plugin status"
summary = "Show plugin status."
handler = "${token}_cmd_status"
EOF
    cat > "$dir/src/commands.sh" <<EOF
${token}_cmd_status() {
    plugin_status "$plugin"
}
EOF
    cat > "$dir/lifecycle.sh" <<'EOF'
plugin_setup() {
    plugin_ensure_settings "$AIR_PLUGIN"
}

plugin_enable() {
    log_success "Plugin enabled."
}

plugin_disable() {
    log_success "Plugin disabled."
}

plugin_reset() {
    rm -rf "$AIR_PLUGIN_DATA_DIR"
    log_success "Plugin reset completed."
}

plugin_status() {
    ui kv "插件" "$AIR_PLUGIN"
    ui kv "状态" "$(plugin_is_enabled "$AIR_PLUGIN" && printf enabled || printf disabled)"
    ui kv "Setup" "$(plugin_is_setup "$AIR_PLUGIN" && printf ready || printf missing)"
}
EOF
    cat > "$dir/runtime.sh" <<'EOF'
runtime_init() {
    case "${1:-bash}" in
        bash) ;;
        *) return 0 ;;
    esac
}
EOF
    cat > "$dir/src/state.sh" <<EOF
${plugin}_data_dir() {
    plugin_data_dir "$plugin"
}
EOF
    cat > "$dir/settings.sh" <<EOF
# $plugin plugin settings.
EOF
    cat > "$dir/README.md" <<EOF
# $plugin

Air plugin scaffold.
EOF
    log_success "已创建插件骨架: $dir"
}

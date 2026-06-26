# Env command handlers.

_env_ready() {
    env_setup_files
}

_env_require_enabled() {
    if ! plugin_is_enabled env; then
        log_error "air env: 插件未启用。先运行 air enable env。"
        return 1
    fi
}

_env_capability_source_label() {
    env_capability_origin "$1"
}

_env_capability_hash_label() {
    env_capability_hash "$1"
}

_env_capability_targets_label() {
    local name="$1" targets target first=1

    targets=
    while IFS= read -r target; do
        if [ "$first" = "1" ]; then
            targets="$target"
            first=0
        else
            targets="$targets,$target"
        fi
    done <<EOF
$(env_capability_targets "$name" 2>/dev/null || true)
EOF
    printf '%s\n' "${targets:-disabled}"
}

_env_option_key() {
    local option="$1"

    option="${option#--}"
    option="${option//-/_}"
    printf '%s\n' "$option"
}

_env_parse_param_args() {
    local arg key value

    declare -gA ENV_PARAM_OVERRIDES
    ENV_PARAM_OVERRIDES=()
    ENV_CONFIGURE_TARGET=""
    while [ "$#" -gt 0 ]; do
        arg="$1"
        case "$arg" in
            --yes|-y)
                AIR_YES=1
                export AIR_YES
                shift
                ;;
            --non-interactive)
                AIR_NON_INTERACTIVE=1
                export AIR_NON_INTERACTIVE
                shift
                ;;
            --plain)
                AIR_PLAIN=1
                NO_COLOR=1
                export AIR_PLAIN NO_COLOR
                shift
                ;;
            --target)
                ENV_CONFIGURE_TARGET="${2:-}"
                shift 2
                ;;
            --set)
                value="${2:-}"
                key="${value%%=*}"
                value="${value#*=}"
                env_validate_name "$key" || {
                    log_error "air env: invalid --set key: $key"
                    return 1
                }
                ENV_PARAM_OVERRIDES["$key"]="$value"
                shift 2
                ;;
            --*=*)
                key="$(_env_option_key "${arg%%=*}")"
                value="${arg#*=}"
                env_validate_name "$key" || {
                    log_error "air env: invalid option: $arg"
                    return 1
                }
                ENV_PARAM_OVERRIDES["$key"]="$value"
                shift
                ;;
            --*)
                key="$(_env_option_key "$arg")"
                value="${2:-}"
                env_validate_name "$key" || {
                    log_error "air env: invalid option: $arg"
                    return 1
                }
                [ -n "$value" ] || {
                    log_error "air env: option requires a value: $arg"
                    return 1
                }
                ENV_PARAM_OVERRIDES["$key"]="$value"
                shift 2
                ;;
            *)
                log_error "air env: unknown argument: $arg"
                return 1
                ;;
        esac
    done
}

_env_input_env_value() {
    local name="$1" input="$2" env_name value

    env_name="$(env_capability_input_value "$name" "$input" env 2>/dev/null || true)"
    [ -n "$env_name" ] || return 1
    eval "value=\"\${$env_name:-}\""
    [ -n "$value" ] || return 1
    printf '%s\n' "$value"
}

_env_configure_capability_params() {
    local name="$1" target="${2:-}" force_prompt="${3:-0}"
    local input prompt required value current default env_value applies_any=0
    local -a pairs

    env_capability_exists "$name" || {
        log_error "air env configure: 未注册能力: $name"
        return 1
    }

    pairs=()
    for input in $(env_capability_input_names "$name"); do
        if [ -n "$target" ] && ! env_capability_input_applies_to_target "$name" "$input" "$target"; then
            continue
        fi
        applies_any=1
        prompt="$(env_capability_input_value "$name" "$input" prompt 2>/dev/null || printf '%s' "$input")"
        required="$(env_capability_input_value "$name" "$input" required 2>/dev/null || printf 'false')"

        if [ "${ENV_PARAM_OVERRIDES[$input]+x}" ]; then
            value="${ENV_PARAM_OVERRIDES[$input]}"
        else
            current="$(env_capability_param_value "$name" "$input" 2>/dev/null || true)"
            env_value="$(_env_input_env_value "$name" "$input" 2>/dev/null || true)"
            default="$(env_capability_input_value "$name" "$input" default 2>/dev/null || true)"
            value="${current:-${env_value:-$default}}"
            if [ "$force_prompt" = "1" ] && [ "${AIR_YES:-0}" != "1" ] && ui_is_interactive; then
                value="$(ui input --prompt "$prompt" --default "$value" $([ "$required" = "true" ] && printf -- '--required'))" || return 1
            fi
        fi

        if [ -z "$value" ]; then
            case "$required" in
                true|yes|1)
                    ui check-item error "$input" "Required input is missing."
                    return 1
                    ;;
            esac
        fi
        pairs+=("$input" "$value")
    done

    [ "$applies_any" = "1" ] || return 0
    env_write_capability_params "$name" "${pairs[@]}"
}

_env_list() {
    local name

    _env_ready || return 1
    {
        printf 'CAPABILITY\tKIND\tTARGETS\tPARAMS\tSOURCE\tHASH\n'
        for name in $(env_capability_names); do
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$name" \
                "$(env_capability_kind "$name")" \
                "$(_env_capability_targets_label "$name")" \
                "$(env_capability_param_summary "$name")" \
                "$(_env_capability_source_label "$name")" \
                "$(_env_capability_hash_label "$name" | cut -c1-12)"
        done
    } | ui table
}

_env_add() {
    local name="${1:-}"

    _env_require_enabled || return 1
    _env_ready || return 1
    [ -n "$name" ] || {
        log_error "用法: air env add <local-bin|nvm|pyenv>"
        log_warn "可用内置能力: $(env_builtin_capability_names | paste -sd ',' -)"
        return 1
    }
    env_add_builtin_capability "$name" || return 1
    log_success "已安装内置 env 能力: $name"
}

_env_register() {
    local name="${1:-}" script="${2:-}"

    _env_require_enabled || return 1
    _env_ready || return 1
    [ -n "$name" ] && [ -n "$script" ] || {
        log_error "用法: air env register <name> <script>"
        return 1
    }
    env_register_capability "$name" "$script" || return 1
    log_success "已注册 env 能力: $name"
}

_env_unregister() {
    local name="${1:-}"

    _env_require_enabled || return 1
    _env_ready || return 1
    [ -n "$name" ] || {
        log_error "用法: air env unregister <name>"
        return 1
    }
    env_unregister_capability "$name" || return 1
    env_refresh_bash_env || true
    log_success "已删除 env 能力: $name"
}

_env_validate() {
    local name="${1:-}" target="${2:-bashrc}"

    _env_require_enabled || return 1
    _env_ready || return 1
    [ -n "$name" ] || {
        log_error "用法: air env validate <name> [bashrc|bash-env]"
        return 1
    }
    env_validate_capability_for_target "$name" "$target" || return 1
    log_success "能力可安全加载: $name -> $target"
}

_env_activate() {
    local name="${1:-}" target="${2:-}" force_prompt=0

    _env_require_enabled || return 1
    _env_ready || return 1
    [ -n "$name" ] && [ -n "$target" ] || {
        log_error "用法: air env activate <name> <bashrc|bash-env> [--set key=value] [--nvm-dir path]"
        return 1
    }
    shift 2
    _env_parse_param_args "$@" || return 1
    if [ ! -r "$(env_capability_params_path "$name")" ] && [ -n "$(env_capability_input_names "$name" | sed -n '1p')" ]; then
        force_prompt=1
    fi
    _env_configure_capability_params "$name" "$target" "$force_prompt" || return 1
    env_validate_capability_for_target "$name" "$target" || return 1
    if [ "${AIR_ENV_FEASIBILITY_WARNINGS:-0}" -gt 0 ]; then
        ui confirm \
            --title "Env capability has warnings: $name -> $target" \
            --message "Activate anyway?" \
            --risk medium \
            --default no \
            --non-tty deny || return 1
    fi
    env_target_add_capability "$target" "$name" || return 1
    env_refresh_target_runtime "$target" || return 1
    log_success "已激活 env 能力: $name -> $target"
}

_env_configure() {
    local name="${1:-}" target active_target status=0

    _env_require_enabled || return 1
    _env_ready || return 1
    [ -n "$name" ] || {
        log_error "用法: air env configure <name> [--target bashrc|bash-env] [--set key=value]"
        return 1
    }
    shift
    _env_parse_param_args "$@" || return 1
    target="$ENV_CONFIGURE_TARGET"
    [ -z "$target" ] || env_validate_target "$target" || {
        log_error "air env configure: 不支持目标: $target"
        return 1
    }
    _env_configure_capability_params "$name" "$target" 1 || return 1
    if [ -n "$target" ]; then
        env_validate_capability_for_target "$name" "$target" || return 1
        env_refresh_target_runtime "$target" || return 1
    else
        for active_target in $(env_capability_targets "$name"); do
            env_validate_capability_for_target "$name" "$active_target" || status=1
            env_refresh_target_runtime "$active_target" || status=1
        done
    fi
    [ "$status" = "0" ] || return 1
    log_success "已配置 env 能力: $name"
}

_env_deactivate() {
    local name="${1:-}" target="${2:-}"

    _env_require_enabled || return 1
    _env_ready || return 1
    [ -n "$name" ] && [ -n "$target" ] || {
        log_error "用法: air env deactivate <name> <bashrc|bash-env>"
        return 1
    }
    env_target_remove_capability "$target" "$name" || return 1
    env_refresh_target_runtime "$target" || return 1
    log_success "已停用 env 能力: $name -> $target"
}

_env_refresh() {
    _env_require_enabled || return 1
    _env_ready || return 1
    env_refresh_runtimes || return 1
    log_success "已刷新 env runtime: $(env_runtime_dir)"
}

_env_inject_status() {
    local target="${1:-bash-env}" profile_marker runtime_state flag_state

    case "$target" in
        bash-env) ;;
        *)
            log_error "用法: air env inject status [bash-env]"
            return 1
            ;;
    esac
    if env_has_marker "$HOME/.profile" "$(env_bash_env_profile_begin)" "$(env_bash_env_profile_end)"; then
        profile_marker="installed"
    else
        profile_marker="missing"
    fi
    if [ -r "$(env_bash_env_path)" ]; then
        runtime_state="ready"
    else
        runtime_state="missing"
    fi
    if env_inject_is_enabled "$target"; then
        flag_state="enabled"
    else
        flag_state="disabled"
    fi

    ui kv "inject target" "$target"
    ui kv "flag" "$flag_state"
    ui kv "profile marker" "$profile_marker"
    ui kv "runtime" "$runtime_state ($(env_bash_env_path))"
}

_env_inject() {
    local action="${1:-}" target="${2:-bash-env}"

    _env_ready || return 1
    case "$action" in
        enable)
            _env_require_enabled || return 1
            env_enable_inject_target "$target" || return 1
            log_success "已启用 env 注入: $target"
            ;;
        disable)
            env_disable_inject_target "$target" || return 1
            log_success "已停用 env 注入: $target"
            ;;
        status|'')
            _env_inject_status "$target"
            ;;
        *)
            log_error "用法: air env inject <enable|disable|status> bash-env"
            return 1
            ;;
    esac
}

_env_probe_bashrc() {
    local output status

    ui kv "bashrc probe" "running (timeout 8s)"
    output="$(timeout 8 bash -ic 'command -v node; node -v; command -v npm; npm -v; type -t nvm; command -v pyenv; python --version' 2>&1)"
    status="$?"
    if [ "$status" = "0" ]; then
        ui kv "bashrc probe" "ok"
    else
        ui kv "bashrc probe" "failed"
    fi
    printf '%s\n' "$output" | ui code
}

_env_probe_bash_env() {
    local runtime output status

    runtime="$(env_bash_env_path)"
    if [ ! -r "$runtime" ]; then
        ui kv "bash-env probe" "missing runtime"
        return 0
    fi
    ui kv "bash-env probe" "running (timeout 8s)"
    output="$(timeout 8 env BASH_ENV="$runtime" bash -c 'command -v node; node -v; command -v npm; npm -v; command -v python; python --version; command -v pip; pip --version | sed -n "1p"' 2>&1)"
    status="$?"
    if [ "$status" = "0" ]; then
        ui kv "bash-env probe" "ok"
    else
        ui kv "bash-env probe" "failed"
    fi
    printf '%s\n' "$output" | ui code
}

_env_analysis() {
    local name target current_node current_pyenv bashrc_marker profile_bash_env_marker bash_env_flag parent_coverage run_probe=0

    _env_ready || return 1
    case "${1:-}" in
        --probe|-p)
            run_probe=1
            ;;
        '')
            ;;
        *)
            log_error "用法: air env analysis [--probe]"
            return 1
            ;;
    esac
    current_node="$(command -v node 2>/dev/null || true)"
    current_pyenv="$(command -v pyenv 2>/dev/null || true)"
    if env_has_marker "$HOME/.bashrc" "$(env_air_bashrc_begin)" "$(env_air_bashrc_end)"; then
        bashrc_marker="installed"
    else
        bashrc_marker="missing"
    fi
    if env_has_marker "$HOME/.profile" '# >>> air env bash-env >>>' '# <<< air env bash-env <<<'; then
        profile_bash_env_marker="present"
    else
        profile_bash_env_marker="absent"
    fi
    if env_inject_is_enabled bash-env; then
        bash_env_flag="enabled"
    else
        bash_env_flag="disabled"
    fi
    if [ -n "${BASH_ENV:-}" ]; then
        parent_coverage="已继承"
    else
        parent_coverage="未继承；login shell 和交互 shell 的子 bash 已覆盖，当前已运行父进程需重启或手动 export"
    fi

    ui kv "插件" "env"
    ui kv "状态" "$(plugin_is_enabled env && printf enabled || printf disabled)"
    ui kv "Setup" "$(plugin_is_setup env && printf ready || printf missing)"
    ui kv "状态目录" "$(env_data_dir)"
    ui kv "bashrc Air marker" "$bashrc_marker"
    ui kv "profile BASH_ENV marker" "$profile_bash_env_marker"
    ui kv "bash-env inject flag" "$bash_env_flag"
    ui kv "bash-env runtime" "$(env_bash_env_path)"
    ui kv "bashrc runtime" "$(env_bashrc_runtime_path)"
    ui kv "当前 BASH_ENV" "${BASH_ENV:-unset}"
    ui kv "父进程覆盖" "$parent_coverage"
    ui kv "当前 CLI shell node" "${current_node:-missing (not sourced by this non-interactive command)}"
    ui kv "当前 CLI shell pyenv" "${current_pyenv:-missing (not sourced by this non-interactive command)}"
    for target in $(env_target_names); do
        ui kv "$target targets" "$(env_target_capabilities "$target" | paste -sd ',' - 2>/dev/null || true)"
    done
    _env_list
    if [ "$run_probe" = "1" ]; then
        _env_probe_bashrc
        _env_probe_bash_env
    else
        ui kv "probe" "skipped (run 'air env analysis --probe')"
    fi
}

env_cmd_list() { _env_list "$@"; }
env_cmd_add() { _env_add "$@"; }
env_cmd_register() { _env_register "$@"; }
env_cmd_unregister() { _env_unregister "$@"; }
env_cmd_validate() { _env_validate "$@"; }
env_cmd_activate() { _env_activate "$@"; }
env_cmd_configure() { _env_configure "$@"; }
env_cmd_deactivate() { _env_deactivate "$@"; }
env_cmd_refresh() { _env_refresh "$@"; }
env_cmd_inject() { _env_inject "$@"; }
env_cmd_analysis() { _env_analysis "$@"; }

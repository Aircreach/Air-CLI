# Env plugin state, capability registry, and bash runtime helpers.

env_data_dir() {
    plugin_data_dir env
}

env_capabilities_dir() {
    printf '%s\n' "$(env_data_dir)/capabilities"
}

env_capability_dir() {
    printf '%s\n' "$(env_capabilities_dir)/$1"
}

env_capability_meta_path() {
    printf '%s\n' "$(env_capability_dir "$1")/resource.toml"
}

env_capability_targets_dir() {
    printf '%s\n' "$(env_capability_dir "$1")/targets"
}

env_capability_config_dir() {
    printf '%s\n' "$(plugin_config_dir env)/capabilities/$1"
}

env_capability_params_path() {
    printf '%s\n' "$(env_capability_config_dir "$1")/params.sh"
}

env_capability_target_loader_path() {
    local name="$1" target="$2" loader

    env_validate_name "$name" || return 1
    env_validate_target "$target" || return 1
    loader="$(plugin_toml_value "$(env_capability_meta_path "$name")" "targets.$target.loader" 2>/dev/null || true)"
    case "$loader" in
        ''|/*|*../*|../*|*'/..'|*'..')
            return 1
            ;;
    esac
    printf '%s\n' "$(env_capability_dir "$name")/$loader"
}

env_runtime_dir() {
    plugin_runtime_dir env
}

env_bashrc_runtime_path() {
    printf '%s\n' "$(env_runtime_dir)/bashrc.bash"
}

env_bash_env_path() {
    printf '%s\n' "$(env_runtime_dir)/bash_env.bash"
}

env_inject_dir() {
    printf '%s\n' "$(plugin_config_dir env)/inject"
}

env_inject_flag_path() {
    case "$1" in
        bash-env)
            printf '%s\n' "$(env_inject_dir)/bash-env.enabled"
            ;;
        *)
            return 1
            ;;
    esac
}

env_targets_dir() {
    printf '%s\n' "$(plugin_config_dir env)/targets"
}

env_target_list_path() {
    case "$1" in
        bashrc)
            printf '%s\n' "$(env_targets_dir)/bashrc.list"
            ;;
        bash-env)
            printf '%s\n' "$(env_targets_dir)/bash-env.list"
            ;;
        *)
            return 1
            ;;
    esac
}

env_builtin_capabilities_dir() {
    local path

    path="$(plugin_meta_value env capabilities.path 2>/dev/null || printf 'src/capabilities')"
    printf '%s\n' "$(plugin_dir env)/$path"
}

env_backups_dir() {
    printf '%s\n' "$(plugin_cache_dir env)/backups"
}

env_settings_path() {
    plugin_settings_path env
}

env_ensure_dirs() {
    mkdir -p "$(env_capabilities_dir)" "$(env_targets_dir)" "$(env_runtime_dir)" "$(env_inject_dir)"
}

env_setup_files() {
    env_ensure_dirs
    plugin_ensure_settings env
    env_sync_builtin_capability_inputs
}

env_validate_name() {
    case "${1:-}" in
        ''|.*|*/*|*[^A-Za-z0-9._-]*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

env_validate_target() {
    case "${1:-}" in
        bashrc|bash-env)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

env_shell_quote() {
    local value="$1"

    value="${value//\'/\'\\\'\'}"
    printf "'%s'" "$value"
}

env_param_var_name() {
    local name="$1" key="$2"

    printf 'AIR_ENV_PARAM_%s_%s\n' "$name" "$key" | tr '[:lower:]' '[:upper:]' | sed 's/[-.]/_/g'
}

env_expand_path_value() {
    local value="$1"

    case "$value" in
        '~')
            printf '%s\n' "$HOME"
            ;;
        '~/'*)
            printf '%s/%s\n' "$HOME" "${value#~/}"
            ;;
        '$HOME')
            printf '%s\n' "$HOME"
            ;;
        '$HOME/'*)
            printf '%s/%s\n' "$HOME" "${value#\$HOME/}"
            ;;
        *)
            printf '%s\n' "$value"
            ;;
    esac
}

env_hash_file() {
    sha256sum "$1" | awk '{print $1}'
}

env_now() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

env_capability_exists() {
    env_validate_name "$1" || return 1
    [ -r "$(env_capability_meta_path "$1")" ]
}

env_capability_names() {
    local dir name

    [ -d "$(env_capabilities_dir)" ] || return 0
    for dir in "$(env_capabilities_dir)"/*; do
        [ -d "$dir" ] || continue
        [ -r "$dir/resource.toml" ] || continue
        [ -d "$dir/targets" ] || continue
        name="${dir##*/}"
        env_validate_name "$name" && printf '%s\n' "$name"
    done
}

env_toml_value() {
    local file="$1" key="$2" line value

    [ -r "$file" ] || return 1
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"
        case "$line" in
            "$key"\ =*)
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

env_toml_raw_value() {
    local file="$1" key="$2" line value

    [ -r "$file" ] || return 1
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"
        case "$line" in
            "$key"\ =*)
                value="${line#*=}"
                value="${value#"${value%%[![:space:]]*}"}"
                printf '%s\n' "$value"
                return 0
                ;;
        esac
    done < "$file"
    return 1
}

env_capability_kind() {
    env_toml_value "$(env_capability_meta_path "$1")" kind 2>/dev/null || printf 'custom\n'
}

env_capability_origin() {
    env_toml_value "$(env_capability_meta_path "$1")" source 2>/dev/null || printf 'unknown\n'
}

env_capability_hash() {
    env_toml_value "$(env_capability_meta_path "$1")" sha256 2>/dev/null || printf 'unknown\n'
}

env_capability_summary() {
    env_toml_value "$(env_capability_meta_path "$1")" summary 2>/dev/null || printf 'No summary.\n'
}

env_capability_input_names() {
    local name="$1" meta line input

    meta="$(env_capability_meta_path "$name")"
    [ -r "$meta" ] || return 0
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"
        case "$line" in
            '[inputs.'*']')
                input="${line#\[inputs.}"
                input="${input%\]}"
                env_validate_name "$input" && printf '%s\n' "$input"
                ;;
        esac
    done < "$meta"
}

env_capability_input_value() {
    local name="$1" input="$2" field="$3"

    plugin_toml_value "$(env_capability_meta_path "$name")" "inputs.$input.$field"
}

env_capability_input_applies_to_target() {
    local name="$1" input="$2" target="$3" raw

    raw="$(env_toml_raw_value "$(env_capability_meta_path "$name")" "targets" 2>/dev/null || true)"
    raw="$(plugin_toml_value "$(env_capability_meta_path "$name")" "inputs.$input.targets" 2>/dev/null || true)"
    [ -n "$raw" ] || return 0
    case "$raw" in
        *"$target"*) return 0 ;;
        *) return 1 ;;
    esac
}

env_capability_param_value() {
    local name="$1" input="$2" params var value

    params="$(env_capability_params_path "$name")"
    var="$(env_param_var_name "$name" "$input")"
    [ -r "$params" ] || return 1
    value="$(
        params="$params" var="$var" bash -c '
            set +e
            . "$params" >/dev/null 2>&1 || exit 1
            eval "printf \"%s\\n\" \"\${$var:-}\""
        ' 2>/dev/null
    )" || return 1
    [ -n "$value" ] || return 1
    printf '%s\n' "$value"
}

env_capability_param_or_default() {
    local name="$1" input="$2" default

    env_capability_param_value "$name" "$input" 2>/dev/null && return 0
    default="$(env_capability_input_value "$name" "$input" default 2>/dev/null || true)"
    printf '%s\n' "$default"
}

env_capability_param_summary() {
    local name="$1" input value first=1 summary=""

    for input in $(env_capability_input_names "$name"); do
        value="$(env_capability_param_or_default "$name" "$input" 2>/dev/null || true)"
        [ -n "$value" ] || continue
        if [ "$first" = "1" ]; then
            summary="$input=$value"
            first=0
        else
            summary="$summary,$input=$value"
        fi
    done
    printf '%s\n' "${summary:--}"
}

env_write_capability_params() {
    local name="$1" input value var params tmp

    shift
    params="$(env_capability_params_path "$name")"
    tmp="$(mktemp)"
    {
        printf '# Generated by Air env. Edit with air env configure %s.\n' "$name"
        while [ "$#" -gt 1 ]; do
            input="$1"
            value="$2"
            shift 2
            var="$(env_param_var_name "$name" "$input")"
            printf '%s=%s\n' "$var" "$(env_shell_quote "$value")"
        done
    } > "$tmp"
    mkdir -p "$(dirname "$params")"
    cp "$tmp" "$params"
    chmod 0644 "$params"
    rm -f "$tmp"
}

env_capability_supports_target() {
    [ -r "$(env_capability_target_loader_path "$1" "$2" 2>/dev/null)" ]
}

env_capability_target_mode() {
    plugin_toml_value "$(env_capability_meta_path "$1")" "targets.$2.mode" 2>/dev/null || printf 'custom\n'
}

env_capability_target_summary() {
    plugin_toml_value "$(env_capability_meta_path "$1")" "targets.$2.summary" 2>/dev/null || env_capability_summary "$1"
}

env_builtin_capability_dir() {
    printf '%s\n' "$(env_builtin_capabilities_dir)/$1"
}

env_builtin_capability_exists() {
    env_validate_name "$1" || return 1
    [ -r "$(env_builtin_capability_dir "$1")/capability.toml" ] || return 1
    [ -d "$(env_builtin_capability_dir "$1")/targets" ] || return 1
}

env_builtin_capability_names() {
    local dir name

    [ -d "$(env_builtin_capabilities_dir)" ] || return 0
    for dir in "$(env_builtin_capabilities_dir)"/*; do
        [ -d "$dir" ] || continue
        [ -r "$dir/capability.toml" ] || continue
        [ -d "$dir/targets" ] || continue
        name="${dir##*/}"
        env_validate_name "$name" && printf '%s\n' "$name"
    done
}

env_sync_builtin_capability_inputs() {
    local name template

    for name in $(env_capability_names); do
        [ "$(env_capability_kind "$name")" = "builtin" ] || continue
        if [ -n "$(env_capability_input_names "$name" | sed -n '1p')" ]; then
            continue
        fi
        template="$(env_builtin_capability_dir "$name")/capability.toml"
        [ -r "$template" ] || continue
        env_append_capability_inputs_from_template "$name" "$template"
    done
}

env_builtin_capability_target_names() {
    local name="$1" target_dir target

    target_dir="$(env_builtin_capability_dir "$name")/targets"
    [ -d "$target_dir" ] || return 0
    for target in "$target_dir"/*.bash; do
        [ -r "$target" ] || continue
        target="${target##*/}"
        target="${target%.bash}"
        env_validate_target "$target" && printf '%s\n' "$target"
    done
}

env_write_capability_manifest_header() {
    local name="$1" kind="$2" source="$3" hash="$4" registered_at="$5" summary="$6" meta

    meta="$(env_capability_meta_path "$name")"
    {
        printf '# Generated by Air env. Do not edit this file directly.\n'
        printf 'schema = "air.resource/v1"\n'
        printf 'id = "%s"\n' "$name"
        printf 'name = "%s"\n' "$name"
        printf 'kind = "%s"\n' "$kind"
        printf 'source = "%s"\n' "$source"
        printf 'registered_at = "%s"\n' "$registered_at"
        printf 'sha256 = "%s"\n' "$hash"
        printf 'summary = "%s"\n' "$summary"
    } > "$meta"
}

env_append_capability_target_manifest() {
    local name="$1" target="$2" loader="$3" mode="$4" risk="$5" summary="$6" meta

    meta="$(env_capability_meta_path "$name")"
    {
        printf '\n[targets.%s]\n' "$target"
        printf 'loader = "%s"\n' "$loader"
        printf 'mode = "%s"\n' "$mode"
        printf 'risk = "%s"\n' "$risk"
        printf 'summary = "%s"\n' "$summary"
    } >> "$meta"
}

env_append_capability_inputs_from_template() {
    local name="$1" template_meta="$2" meta

    meta="$(env_capability_meta_path "$name")"
    awk '
        /^\[inputs\./ { copy = 1 }
        /^\[/ && $0 !~ /^\[inputs\./ { copy = 0 }
        copy == 1 { print }
    ' "$template_meta" >> "$meta"
}

env_add_builtin_capability() {
    local name="$1" template cap_dir hash summary target loader mode risk target_summary

    env_builtin_capability_exists "$name" || {
        log_error "air env add: 未知内置能力: $name"
        return 1
    }
    template="$(env_builtin_capability_dir "$name")"
    env_ensure_dirs
    cap_dir="$(env_capability_dir "$name")"
    rm -rf "$cap_dir"
    mkdir -p "$cap_dir/targets"
    cp -a "$template/targets/." "$cap_dir/targets/"
    hash="$(env_hash_file "$template/capability.toml")"
    summary="$(env_toml_value "$template/capability.toml" summary 2>/dev/null || printf 'Built-in capability.')"
    env_write_capability_manifest_header "$name" builtin "$template" "$hash" "$(env_now)" "$summary"
    for target in $(env_builtin_capability_target_names "$name"); do
        loader="targets/$target.bash"
        mode="$(plugin_toml_value "$template/capability.toml" "targets.$target.mode" 2>/dev/null || printf 'static')"
        risk="$(plugin_toml_value "$template/capability.toml" "targets.$target.risk" 2>/dev/null || printf 'medium')"
        target_summary="$(plugin_toml_value "$template/capability.toml" "targets.$target.summary" 2>/dev/null || printf '%s' "$summary")"
        env_append_capability_target_manifest "$name" "$target" "$loader" "$mode" "$risk" "$target_summary"
    done
    env_append_capability_inputs_from_template "$name" "$template/capability.toml"
}

env_target_names() {
    printf '%s\n' bashrc bash-env
}

env_target_capabilities() {
    local target="$1" list line

    env_validate_target "$target" || return 1
    list="$(env_target_list_path "$target")" || return 1
    [ -r "$list" ] || return 0
    while IFS= read -r line; do
        case "$line" in
            ''|\#*) continue ;;
        esac
        env_validate_name "$line" && printf '%s\n' "$line"
    done < "$list"
}

env_capability_targets() {
    local capability="$1" target item

    for target in $(env_target_names); do
        while IFS= read -r item; do
            [ "$item" = "$capability" ] && {
                printf '%s\n' "$target"
                break
            }
        done <<EOF
$(env_target_capabilities "$target" 2>/dev/null || true)
EOF
    done
}

env_register_capability() {
    local name="$1" script="$2" cap_dir source hash

    env_validate_name "$name" || {
        log_error "air env register: 无效能力名: $name"
        return 1
    }
    [ -r "$script" ] || {
        log_error "air env register: 脚本不可读: $script"
        return 1
    }
    bash -n "$script" || {
        log_error "air env register: 脚本语法检查失败: $script"
        return 1
    }

    env_ensure_dirs
    cap_dir="$(env_capability_dir "$name")"
    rm -rf "$cap_dir"
    mkdir -p "$cap_dir/targets"
    cp -a "$script" "$cap_dir/targets/bashrc.bash"

    source="$(cd "$(dirname "$script")" 2>/dev/null && pwd)/$(basename "$script")"
    hash="$(env_hash_file "$cap_dir/targets/bashrc.bash")"
    env_write_capability_manifest_header "$name" custom "$source" "$hash" "$(env_now)" "Custom shell capability."
    env_append_capability_target_manifest "$name" bashrc "targets/bashrc.bash" custom medium "Loads the registered custom shell capability in interactive Bash."
}

env_unregister_capability() {
    local name="$1" target

    env_validate_name "$name" || {
        log_error "air env unregister: 无效能力名: $name"
        return 1
    }
    for target in $(env_target_names); do
        env_target_remove_capability "$target" "$name" || true
    done
    rm -rf "$(env_capability_dir "$name")"
}

env_static_risk_scan() {
    local script="$1" target="$2" kind="${3:-custom}" hit

    case "$target" in
        bashrc|bash-env) ;;
        *) return 1 ;;
    esac

    hit="$(grep -nE '(^|[;&|[:space:]])(sudo[[:space:]]|mkfs(\.|[[:space:]]|$)|shutdown([[:space:]]|$)|reboot([[:space:]]|$)|poweroff([[:space:]]|$)|wsl\.exe[[:space:]].*--shutdown|exec[[:space:]]|exit([[:space:]]|$)|set[[:space:]]+-?e([[:space:]]|$)|set[[:space:]]+-o[[:space:]]+errexit)' "$script" 2>/dev/null | head -n1 || true)"
    if [ -n "$hit" ]; then
        log_error "air env activate: 能力脚本包含不适合 shell 启动的语句:"
        printf '%s\n' "$hit" | sed 's/^/  /'
        return 1
    fi

    hit="$(grep -nE 'rm[[:space:]][^#]*(^|[[:space:]])-r[f]?[[:space:]][^#]*/' "$script" 2>/dev/null | head -n1 || true)"
    if [ -n "$hit" ]; then
        log_error "air env activate: 能力脚本包含高风险 rm 语句:"
        printf '%s\n' "$hit" | sed 's/^/  /'
        return 1
    fi

    if [ "$kind" != "builtin" ]; then
        hit="$(grep -nE '(^|[;&|[:space:]])(eval|source|\.|cd|pushd|popd|read|select)[[:space:]]' "$script" 2>/dev/null | head -n1 || true)"
        if [ -n "$hit" ]; then
            log_error "air env activate: 自定义能力包含需要高级信任的 shell 语句:"
            printf '%s\n' "$hit" | sed 's/^/  /'
            log_warn "普通用法优先使用 air env add <内置能力>；复杂初始化应沉淀为受控内置能力。"
            return 1
        fi

        hit="$(grep -nE '(^|[;&|[:space:]])(alias|unalias|PROMPT_COMMAND=|PS1=|bind[[:space:]])' "$script" 2>/dev/null | head -n1 || true)"
        if [ -n "$hit" ]; then
            log_error "air env activate: 自定义能力包含交互界面改动，不适合 env 能力:"
            printf '%s\n' "$hit" | sed 's/^/  /'
            return 1
        fi
    fi

    return 0
}

env_bash_env_static_scan() {
    local script="$1" hit

    hit="$(grep -nE '(^|[;&|[:space:]])(eval|source|\.|nvm[[:space:]]+use|pyenv[[:space:]]+init|curl|wget|git|sudo|timeout|sleep|read[[:space:]]|select[[:space:]])' "$script" 2>/dev/null | head -n1 || true)"
    if [ -n "$hit" ]; then
        log_error "air env activate: bash-env loader 必须保持静态轻量，发现不允许的语句:"
        printf '%s\n' "$hit" | sed 's/^/  /'
        return 1
    fi

    hit="$(grep -nE '(^|[;&|[:space:]])(nvm\.sh|bash_completion|pyenv init|nvm use)' "$script" 2>/dev/null | head -n1 || true)"
    if [ -n "$hit" ]; then
        log_error "air env activate: bash-env loader 不能加载交互初始化逻辑:"
        printf '%s\n' "$hit" | sed 's/^/  /'
        return 1
    fi

    return 0
}

env_feasibility_reset() {
    AIR_ENV_FEASIBILITY_ERRORS=0
    AIR_ENV_FEASIBILITY_WARNINGS=0
    AIR_ENV_FEASIBILITY_QUIET="${AIR_ENV_FEASIBILITY_QUIET:-0}"
}

env_feasibility_issue() {
    local severity="$1" title="$2" message="$3"

    case "$severity" in
        error|blocked)
            AIR_ENV_FEASIBILITY_ERRORS=$((AIR_ENV_FEASIBILITY_ERRORS + 1))
            ;;
        warning|warn)
            AIR_ENV_FEASIBILITY_WARNINGS=$((AIR_ENV_FEASIBILITY_WARNINGS + 1))
            ;;
    esac

    [ "${AIR_ENV_FEASIBILITY_QUIET:-0}" = "1" ] && return 0
    ui check-item "$severity" "$title" "$message"
}

env_check_path_portability() {
    local input="$1" value="$2"

    case "$value" in
        '$HOME'|'$HOME/'*|'~'|'~/'*)
            return 0
            ;;
        "$HOME"|"$HOME/"*)
            env_feasibility_issue warning "$input" "Path is machine-specific. Prefer \$HOME-relative form: $value"
            ;;
    esac
}

env_nvm_version_bin_for() {
    local nvm_dir="$1" version="$2" candidate

    case "$version" in
        ''|N/A|system|node|stable|unstable|lts/*|iojs*)
            return 1
            ;;
        v*)
            candidate="$nvm_dir/versions/node/$version/bin"
            [ -d "$candidate" ] && {
                printf '%s\n' "$candidate"
                return 0
            }
            ;;
        *)
            candidate="$nvm_dir/versions/node/$version/bin"
            [ -d "$candidate" ] && {
                printf '%s\n' "$candidate"
                return 0
            }
            for candidate in "$nvm_dir/versions/node/v$version"*; do
                [ -d "$candidate/bin" ] || continue
                printf '%s\n' "$candidate/bin"
                return 0
            done
            ;;
    esac
    return 1
}

env_check_capability_inputs_for_target() {
    local name="$1" target="$2" input type required validate value expanded

    for input in $(env_capability_input_names "$name"); do
        env_capability_input_applies_to_target "$name" "$input" "$target" || continue
        type="$(env_capability_input_value "$name" "$input" type 2>/dev/null || printf 'string')"
        required="$(env_capability_input_value "$name" "$input" required 2>/dev/null || printf 'false')"
        validate="$(env_capability_input_value "$name" "$input" validate 2>/dev/null || true)"
        value="$(env_capability_param_or_default "$name" "$input" 2>/dev/null || true)"

        if [ -z "$value" ]; then
            case "$required" in
                true|yes|1)
                    env_feasibility_issue error "$input" "Required input is not configured."
                    ;;
                *)
                    env_feasibility_issue warning "$input" "Input is not configured."
                    ;;
            esac
            continue
        fi

        if [ "$type" = "path" ]; then
            expanded="$(env_expand_path_value "$value")"
            env_check_path_portability "$input" "$value"
            case "$validate" in
                dir)
                    [ -d "$expanded" ] || env_feasibility_issue error "$input" "Directory does not exist: $expanded"
                    ;;
                dir-optional)
                    [ -d "$expanded" ] || env_feasibility_issue warning "$input" "Directory does not exist yet: $expanded"
                    ;;
            esac
        fi
    done
}

env_check_builtin_feasibility() {
    local name="$1" target="$2" nvm_dir nvm_dir_expanded node_version alias_value bin pyenv_root pyenv_root_expanded bin_dir bin_dir_expanded

    case "$name" in
        nvm)
            nvm_dir="$(env_capability_param_or_default nvm nvm_dir 2>/dev/null || printf '$HOME/.nvm')"
            nvm_dir_expanded="$(env_expand_path_value "$nvm_dir")"
            node_version="$(env_capability_param_or_default nvm node_version 2>/dev/null || printf 'default')"
            if [ ! -d "$nvm_dir_expanded" ]; then
                env_feasibility_issue error "nvm_dir" "nvm directory is missing: $nvm_dir_expanded"
                return 0
            fi
            if [ "$target" = "bashrc" ] && [ ! -s "$nvm_dir_expanded/nvm.sh" ]; then
                env_feasibility_issue error "nvm" "nvm.sh is missing: $nvm_dir_expanded/nvm.sh"
            fi
            if [ "$target" = "bash-env" ]; then
                if [ "$node_version" = "default" ]; then
                    if [ -r "$nvm_dir_expanded/alias/default" ]; then
                        IFS= read -r alias_value < "$nvm_dir_expanded/alias/default" || true
                    else
                        alias_value=""
                    fi
                else
                    alias_value="$node_version"
                fi
                if env_nvm_version_bin_for "$nvm_dir_expanded" "$alias_value" >/dev/null 2>&1; then
                    env_feasibility_issue ok "nvm bash-env" "Node bin can be resolved from $nvm_dir."
                elif [ "$node_version" = "default" ]; then
                    env_feasibility_issue warning "nvm bash-env" "default alias cannot be statically resolved; bash-env will skip Node PATH until a concrete version is configured."
                else
                    env_feasibility_issue error "nvm bash-env" "Configured node version is not installed: $node_version"
                fi
            fi
            ;;
        pyenv)
            pyenv_root="$(env_capability_param_or_default pyenv pyenv_root 2>/dev/null || printf '$HOME/.pyenv')"
            pyenv_root_expanded="$(env_expand_path_value "$pyenv_root")"
            if [ ! -d "$pyenv_root_expanded" ]; then
                env_feasibility_issue error "pyenv_root" "pyenv root is missing: $pyenv_root_expanded"
            elif [ ! -d "$pyenv_root_expanded/shims" ] && [ ! -d "$pyenv_root_expanded/bin" ]; then
                env_feasibility_issue warning "pyenv" "pyenv root has no shims or bin directory: $pyenv_root_expanded"
            fi
            ;;
        local-bin)
            bin_dir="$(env_capability_param_or_default local-bin bin_dir 2>/dev/null || printf '$HOME/.local/bin')"
            bin_dir_expanded="$(env_expand_path_value "$bin_dir")"
            [ -d "$bin_dir_expanded" ] || env_feasibility_issue warning "local-bin" "Directory does not exist yet: $bin_dir_expanded"
            ;;
    esac
}

env_check_capability_feasibility() {
    local name="$1" target="$2" quiet="${3:-}" status=0

    AIR_ENV_FEASIBILITY_QUIET=0
    [ "$quiet" = "--quiet" ] && AIR_ENV_FEASIBILITY_QUIET=1
    env_feasibility_reset

    env_check_capability_inputs_for_target "$name" "$target"
    [ "$(env_capability_kind "$name")" = "builtin" ] && env_check_builtin_feasibility "$name" "$target"

    [ "$AIR_ENV_FEASIBILITY_ERRORS" -eq 0 ] || status=1
    return "$status"
}

env_probe_capability() {
    local name="$1" target="$2" script output status

    script="$(env_capability_target_loader_path "$name" "$target")" || return 1
    output="$(AIR_HOME="$AIR_HOME" AIR_STATE_HOME="$AIR_STATE_HOME" timeout 5 bash -c '
        set +e
        script="$1"
        target="$2"
        export AIR_ENV_TARGET="$target"
        export AIR_ENV_PROBE=1
        . "$script" >/dev/null 2>&1 || exit 20
        exit 0
    ' air-env-probe "$script" "$target" 2>&1)"
    status="$?"
    if [ "$status" != "0" ]; then
        log_error "air env activate: 能力 $name 无法安全加载到 $target。"
        [ -n "$output" ] && printf '%s\n' "$output" | sed 's/^/  /'
        return 1
    fi
}

env_validate_capability_for_target() {
    local name="$1" target="$2" script kind

    env_validate_target "$target" || {
        log_error "air env activate: 不支持目标: $target"
        return 1
    }
    env_capability_exists "$name" || {
        log_error "air env activate: 未注册能力: $name"
        return 1
    }
    env_capability_supports_target "$name" "$target" || {
        log_error "air env activate: 能力 $name 不支持目标 $target。"
        return 1
    }
    script="$(env_capability_target_loader_path "$name" "$target")" || {
        log_error "air env activate: 能力 $name 缺少 $target loader。"
        return 1
    }
    kind="$(env_capability_kind "$name")"
    bash -n "$script" || return 1
    if [ "$target" = "bash-env" ]; then
        env_bash_env_static_scan "$script" || return 1
        env_check_capability_feasibility "$name" "$target" || return 1
        return 0
    fi
    env_static_risk_scan "$script" "$target" "$kind" || return 1
    env_check_capability_feasibility "$name" "$target" || return 1
    [ "$kind" = "builtin" ] && return 0
    env_probe_capability "$name" "$target" || return 1
}

env_target_has_capability() {
    local target="$1" capability="$2" item

    while IFS= read -r item; do
        [ "$item" = "$capability" ] && return 0
    done <<EOF
$(env_target_capabilities "$target" 2>/dev/null || true)
EOF
    return 1
}

env_target_add_capability() {
    local target="$1" capability="$2" list tmp item

    env_validate_target "$target" || return 1
    env_validate_name "$capability" || return 1
    env_ensure_dirs
    list="$(env_target_list_path "$target")"
    env_target_has_capability "$target" "$capability" && return 0
    printf '%s\n' "$capability" >> "$list"
}

env_target_remove_capability() {
    local target="$1" capability="$2" list tmp

    env_validate_target "$target" || return 1
    env_validate_name "$capability" || return 1
    list="$(env_target_list_path "$target")"
    [ -e "$list" ] || return 0
    tmp="$(mktemp)"
    awk -v capability="$capability" '$0 != capability { print }' "$list" > "$tmp"
    cp "$tmp" "$list"
    rm -f "$tmp"
}

env_inject_is_enabled() {
    local target="$1" flag

    flag="$(env_inject_flag_path "$target")" || return 1
    [ -f "$flag" ]
}

env_nvm_default_bin() {
    local nvm_dir version dir candidate best bin output status

    nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    if [ -r "$nvm_dir/alias/default" ]; then
        IFS= read -r version < "$nvm_dir/alias/default" || true
        case "$version" in
            ''|N/A|system|default|node|stable|unstable|lts/*|iojs*) ;;
            *)
                bin="$nvm_dir/versions/node/$version/bin"
                if [ -d "$bin" ]; then
                    printf '%s\n' "$bin"
                    return 0
                fi
                best="$(find "$nvm_dir/versions/node" -maxdepth 1 -type d -name "v$version*" 2>/dev/null | sort -V | tail -n 1)"
                if [ -n "$best" ]; then
                    printf '%s\n' "$best/bin"
                    return 0
                fi
                ;;
        esac
    fi

    output="$(HOME="$HOME" timeout 8 bash -c '
        set +e
        export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
        [ -s "$NVM_DIR/nvm.sh" ] || exit 10
        . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || exit 11
        version="$(nvm version default 2>/dev/null)" || exit 12
        case "$version" in
            ""|N/A) exit 13 ;;
        esac
        bin="$NVM_DIR/versions/node/$version/bin"
        [ -d "$bin" ] || exit 14
        printf "%s\n" "$bin"
    ' 2>/dev/null)"
    status="$?"
    if [ "$status" = "0" ] && [ -n "$output" ]; then
        case "$output" in
            /mnt/*)
                log_error "air env refresh: nvm 解析到了 Windows/挂载路径，已拒绝: $output"
                return 1
                ;;
            *)
                printf '%s\n' "$output"
                return 0
                ;;
        esac
    fi

    log_error "air env refresh: 无法解析 nvm default 对应的 Node bin 目录。"
    log_warn "请确认 $HOME/.nvm/nvm.sh 存在，并且 nvm alias default 可用。"
    return 1
}

env_render_param_assignment() {
    local name="$1" input="$2" default="$3" var value

    var="$(env_param_var_name "$name" "$input")"
    value="$(env_capability_param_or_default "$name" "$input" 2>/dev/null || printf '%s' "$default")"
    [ -n "$value" ] || value="$default"
    printf '%s=%s\n' "$var" "$(env_shell_quote "$value")"
}

env_render_local_bin_capability() {
    local target="$1"

    env_render_param_assignment local-bin bin_dir '$HOME/.local/bin'
    cat <<'EOF'
_air_env_expand_path_var "${AIR_ENV_PARAM_LOCAL_BIN_BIN_DIR:-$HOME/.local/bin}"
_air_env_local_bin_dir="$REPLY"
if [ -d "$_air_env_local_bin_dir" ]; then
    _air_env_prepend_path "$_air_env_local_bin_dir"
    export PATH
fi
unset _air_env_local_bin_dir
EOF
}

env_render_nvm_capability() {
    local target="$1"

    env_render_param_assignment nvm nvm_dir '$HOME/.nvm'
    env_render_param_assignment nvm node_version 'default'
    if [ "$target" = "bash-env" ]; then
        cat <<'EOF'
_air_env_expand_path_var "${AIR_ENV_PARAM_NVM_NVM_DIR:-$HOME/.nvm}"
export NVM_DIR="${NVM_DIR:-$REPLY}"
_air_env_nvm_version="${AIR_ENV_PARAM_NVM_NODE_VERSION:-default}"
if [ "$_air_env_nvm_version" = "default" ] && [ -r "$NVM_DIR/alias/default" ]; then
    IFS= read -r _air_env_nvm_version < "$NVM_DIR/alias/default" || true
fi
case "$_air_env_nvm_version" in
    ''|N/A|system|node|stable|unstable|lts/*|iojs*) ;;
    *)
        case "$_air_env_nvm_version" in
            v*) _air_env_nvm_bin="$NVM_DIR/versions/node/$_air_env_nvm_version/bin" ;;
            *) _air_env_nvm_bin="$NVM_DIR/versions/node/$_air_env_nvm_version/bin" ;;
        esac
        if [ ! -d "$_air_env_nvm_bin" ]; then
            for _air_env_nvm_candidate in "$NVM_DIR/versions/node/v$_air_env_nvm_version"*; do
                [ -d "$_air_env_nvm_candidate/bin" ] || continue
                _air_env_nvm_bin="$_air_env_nvm_candidate/bin"
                break
            done
        fi
        if [ -d "$_air_env_nvm_bin" ]; then
            export NVM_BIN="$_air_env_nvm_bin"
            _air_env_prepend_path "$NVM_BIN"
        fi
        ;;
esac
export NVM_DIR PATH
unset _air_env_nvm_version _air_env_nvm_bin _air_env_nvm_candidate
EOF
        return 0
    fi

    cat <<'EOF'
_air_env_expand_path_var "${AIR_ENV_PARAM_NVM_NVM_DIR:-$HOME/.nvm}"
export NVM_DIR="${NVM_DIR:-$REPLY}"
_air_env_nvm_version="${AIR_ENV_PARAM_NVM_NODE_VERSION:-default}"
if [ -n "${NVM_BIN:-}" ] && [ -d "$NVM_BIN" ]; then
    _air_env_prepend_path "$NVM_BIN"
elif [ "$_air_env_nvm_version" = "default" ] && [ -r "$NVM_DIR/alias/default" ]; then
    IFS= read -r _air_env_nvm_version < "$NVM_DIR/alias/default" || true
fi
case "$_air_env_nvm_version" in
    ''|N/A|system|default|node|stable|unstable|lts/*|iojs*) ;;
    *)
        case "$_air_env_nvm_version" in
            v*) _air_env_nvm_bin="$NVM_DIR/versions/node/$_air_env_nvm_version/bin" ;;
            *) _air_env_nvm_bin="$NVM_DIR/versions/node/$_air_env_nvm_version/bin" ;;
        esac
        if [ ! -d "$_air_env_nvm_bin" ]; then
            for _air_env_nvm_candidate in "$NVM_DIR/versions/node/v$_air_env_nvm_version"*; do
                [ -d "$_air_env_nvm_candidate/bin" ] || continue
                _air_env_nvm_bin="$_air_env_nvm_candidate/bin"
                break
            done
        fi
        if [ -d "$_air_env_nvm_bin" ]; then
            export NVM_BIN="$_air_env_nvm_bin"
            _air_env_prepend_path "$NVM_BIN"
        fi
        ;;
esac
export PATH

_air_env_nvm_load() {
    unset -f nvm node npm npx 2>/dev/null || true
    [ -s "$NVM_DIR/nvm.sh" ] || return 127
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    command -v nvm >/dev/null 2>&1 && nvm use --silent default >/dev/null 2>&1 || true
}

nvm() {
    _air_env_nvm_load || return "$?"
    nvm "$@"
}

if ! command -v node >/dev/null 2>&1; then
    node() {
        _air_env_nvm_load || return "$?"
        node "$@"
    }
fi

if ! command -v npm >/dev/null 2>&1; then
    npm() {
        _air_env_nvm_load || return "$?"
        npm "$@"
    }
fi

if ! command -v npx >/dev/null 2>&1; then
    npx() {
        _air_env_nvm_load || return "$?"
        npx "$@"
    }
fi
unset _air_env_nvm_version _air_env_nvm_bin _air_env_nvm_candidate
EOF
}

env_render_pyenv_capability() {
    local target="$1"

    env_render_param_assignment pyenv pyenv_root '$HOME/.pyenv'
    cat <<'EOF'
_air_env_expand_path_var "${AIR_ENV_PARAM_PYENV_PYENV_ROOT:-$HOME/.pyenv}"
export PYENV_ROOT="${PYENV_ROOT:-$REPLY}"
if [ -d "$PYENV_ROOT/shims" ]; then
    _air_env_prepend_path "$PYENV_ROOT/shims"
fi
if [ -d "$PYENV_ROOT/bin" ]; then
    _air_env_prepend_path "$PYENV_ROOT/bin"
fi
export PYENV_ROOT PATH
EOF
    if [ "$target" = "bashrc" ]; then
        cat <<'EOF'

_air_env_pyenv_load() {
    unset -f pyenv 2>/dev/null || true
    command -v pyenv >/dev/null 2>&1 || return 127
    eval "$(command pyenv init --path)"
    eval "$(command pyenv init -)"
}

pyenv() {
    _air_env_pyenv_load || return "$?"
    pyenv "$@"
}
EOF
    fi
}

env_render_capability_for_target() {
    local name="$1" target="$2" script

    script="$(env_capability_target_loader_path "$name" "$target")" || return 1
    printf '\n# capability: %s (%s)\n' "$name" "$target"

    case "$name" in
        local-bin) env_render_local_bin_capability "$target"; return 0 ;;
        nvm) env_render_nvm_capability "$target"; return 0 ;;
        pyenv) env_render_pyenv_capability "$target"; return 0 ;;
    esac

    cat "$script"
}

env_write_runtime_header() {
    local target="$1"

    cat <<EOF
# Generated by Air env. Do not edit this file directly.
# shellcheck shell=bash

if [ -r "\${AIR_STATE_HOME:-\${AIR_USER_HOME:-\$HOME/.air}/state}/plugins/env/enabled" ]; then
    _air_env_prepend_path() {
        case ":\${PATH:-}:" in
            *":\$1:"*) ;;
            *) PATH="\$1\${PATH:+:\$PATH}" ;;
        esac
    }
    _air_env_expand_path_var() {
        REPLY="\$1"
        case "\$REPLY" in
            '~') REPLY="\$HOME" ;;
            '~/'*) REPLY="\$HOME/\${REPLY#~/}" ;;
            '\$HOME') REPLY="\$HOME" ;;
            '\$HOME/'*) REPLY="\$HOME/\${REPLY#\\\$HOME/}" ;;
        esac
    }
EOF
    if [ "$target" = "bash-env" ]; then
        cat <<'EOF'
    if [ -r "${AIR_CONFIG_HOME:-${AIR_USER_HOME:-$HOME/.air}/config}/plugins/env/inject/bash-env.enabled" ]; then
EOF
    fi
}

env_write_runtime_footer() {
    local target="$1"

    if [ "$target" = "bash-env" ]; then
        cat <<'EOF'
    fi
EOF
    fi
    cat <<'EOF'
    unset -f _air_env_prepend_path _air_env_expand_path_var
fi
EOF
}

env_refresh_target_runtime() {
    local target="$1" runtime tmp name

    env_validate_target "$target" || return 1
    case "$target" in
        bashrc) runtime="$(env_bashrc_runtime_path)" ;;
        bash-env) runtime="$(env_bash_env_path)" ;;
    esac

    env_ensure_dirs
    tmp="$(mktemp)"
    {
        env_write_runtime_header "$target"
        while IFS= read -r name; do
            [ -n "$name" ] || continue
            env_render_capability_for_target "$name" "$target" || return 1
        done <<EOF
$(env_target_capabilities "$target" 2>/dev/null || true)
EOF
        env_write_runtime_footer "$target"
    } > "$tmp" || {
        rm -f "$tmp"
        return 1
    }

    bash -n "$tmp" || {
        rm -f "$tmp"
        return 1
    }
    cp "$tmp" "$runtime"
    chmod 0644 "$runtime"
    rm -f "$tmp"
}

env_refresh_bashrc() {
    env_refresh_target_runtime bashrc
}

env_refresh_bash_env() {
    env_refresh_target_runtime bash-env
}

env_refresh_runtimes() {
    env_refresh_bashrc || return 1
    env_refresh_bash_env || return 1
}

env_runtime_export_bash_env() {
    local runtime

    env_inject_is_enabled bash-env || return 0
    runtime="$(env_bash_env_path)"
    [ -r "$runtime" ] || env_refresh_bash_env || return 0
    [ -r "$runtime" ] || return 0
    export BASH_ENV="$runtime"
}

env_runtime_apply_current_shell() {
    env_refresh_runtimes || return 1
    env_runtime_load_target bashrc || true
    env_runtime_export_bash_env || true
}

env_runtime_load_capability() {
    local name="$1" target="$2" script status=0

    env_capability_exists "$name" || return 0
    script="$(env_capability_target_loader_path "$name" "$target" 2>/dev/null)" || return 0

    AIR_ENV_CAPABILITY="$name"
    AIR_ENV_TARGET="$target"
    export AIR_ENV_CAPABILITY AIR_ENV_TARGET

    # shellcheck disable=SC1090
    . "$script" >/dev/null 2>&1 || status="$?"

    unset AIR_ENV_CAPABILITY AIR_ENV_TARGET
    [ "$status" = "0" ] || [ -z "${AIR_ENV_DEBUG:-}" ] || log_warn "env capability skipped: $name ($target)"
    return 0
}

env_runtime_load_target() {
    local target="$1" runtime

    env_validate_target "$target" || return 0
    case "$target" in
        bashrc) runtime="$(env_bashrc_runtime_path)" ;;
        bash-env) runtime="$(env_bash_env_path)" ;;
    esac
    [ -r "$runtime" ] || env_refresh_target_runtime "$target" || return 0
    [ -r "$runtime" ] || return 0
    # shellcheck disable=SC1090
    . "$runtime" >/dev/null 2>&1 || true
}

env_backup_file() {
    local file="$1" backup_dir

    [ -e "$file" ] || return 0
    backup_dir="$(env_backups_dir)/$(date +%Y%m%d-%H%M%S-%N)"
    mkdir -p "$backup_dir"
    cp -a "$file" "$backup_dir/"
}

env_strip_marker() {
    local file="$1" begin="$2" end="$3" tmp

    [ -e "$file" ] || return 0
    tmp="$(mktemp)"
    awk -v begin="$begin" -v end="$end" '
        $0 == begin { skip = 1; next }
        $0 == end { skip = 0; next }
        skip != 1 { print }
    ' "$file" > "$tmp"
    cp "$tmp" "$file"
    rm -f "$tmp"
}

env_has_marker() {
    local file="$1" begin="$2" end="$3"

    [ -r "$file" ] || return 1
    grep -Fxq "$begin" "$file" || return 1
    grep -Fxq "$end" "$file" || return 1
}

env_remove_marker() {
    local file="$1" begin="$2" end="$3"

    [ -e "$file" ] || return 0
    env_has_marker "$file" "$begin" "$end" || return 0
    env_backup_file "$file"
    env_strip_marker "$file" "$begin" "$end"
}

env_air_bashrc_begin() {
    printf '%s\n' '# >>> air core >>>'
}

env_air_bashrc_end() {
    printf '%s\n' '# <<< air core <<<'
}

env_bash_env_profile_begin() {
    printf '%s\n' '# >>> air env bash-env >>>'
}

env_bash_env_profile_end() {
    printf '%s\n' '# <<< air env bash-env <<<'
}

env_install_bash_env_profile_marker() {
    local file="$HOME/.profile" begin end

    begin="$(env_bash_env_profile_begin)"
    end="$(env_bash_env_profile_end)"
    env_backup_file "$file"
    env_strip_marker "$file" "$begin" "$end"
    {
        printf '\n'
        printf '%s\n' "$begin"
        printf 'export AIR_HOME="${AIR_HOME:-$HOME/.local/share/air}"\n'
        printf 'export AIR_USER_HOME="${AIR_USER_HOME:-$HOME/.air}"\n'
        printf 'if [ "${AIR_CONFIG_HOME:-}" = "$AIR_HOME/state" ]; then AIR_CONFIG_HOME="$AIR_USER_HOME/config"; fi\n'
        printf 'if [ "${AIR_STATE_HOME:-}" = "$AIR_HOME/state" ]; then AIR_STATE_HOME="$AIR_USER_HOME/state"; fi\n'
        printf 'export AIR_CONFIG_HOME="${AIR_CONFIG_HOME:-$AIR_USER_HOME/config}"\n'
        printf 'export AIR_STATE_HOME="${AIR_STATE_HOME:-$AIR_USER_HOME/state}"\n'
        printf 'export AIR_RUNTIME_HOME="${AIR_RUNTIME_HOME:-$AIR_USER_HOME/runtime}"\n'
        printf 'if [ -r "$AIR_STATE_HOME/plugins/env/enabled" ] && [ -r "$AIR_CONFIG_HOME/plugins/env/inject/bash-env.enabled" ] && [ -r "$AIR_RUNTIME_HOME/plugins/env/bash_env.bash" ]; then\n'
        printf '    export BASH_ENV="$AIR_RUNTIME_HOME/plugins/env/bash_env.bash"\n'
        printf '    . "$BASH_ENV"\n'
        printf 'fi\n'
        printf '%s\n' "$end"
    } >> "$file"
}

env_enable_inject_target() {
    local target="$1" flag

    case "$target" in
        bash-env) ;;
        *)
            log_error "air env inject enable: 不支持目标: $target"
            return 1
            ;;
    esac
    env_refresh_bash_env || return 1
    flag="$(env_inject_flag_path "$target")" || return 1
    mkdir -p "$(dirname "$flag")"
    printf 'enabled\n' > "$flag"
    env_install_bash_env_profile_marker
    env_runtime_export_bash_env || true
}

env_disable_inject_target() {
    local target="$1" flag

    case "$target" in
        bash-env) ;;
        *)
            log_error "air env inject disable: 不支持目标: $target"
            return 1
            ;;
    esac
    flag="$(env_inject_flag_path "$target")" || return 1
    rm -f "$flag"
    env_remove_marker "$HOME/.profile" "$(env_bash_env_profile_begin)" "$(env_bash_env_profile_end)" || true
}

env_remove_retired_markers() {
    env_remove_marker "$HOME/.profile" '# >>> air env bash-env >>>' '# <<< air env bash-env <<<' || true
    env_remove_marker "$HOME/.profile" '# >>> air env profile >>>' '# <<< air env profile <<<' || true
    env_remove_marker "$HOME/.profile" '# >>> air env >>>' '# <<< air env <<<' || true
    env_remove_marker "$HOME/.bashrc" '# >>> air env bashrc >>>' '# <<< air env bashrc <<<' || true
}

env_remove_shell_markers() {
    env_remove_retired_markers
    env_remove_marker "$HOME/.profile" "$(env_bash_env_profile_begin)" "$(env_bash_env_profile_end)" || true
}

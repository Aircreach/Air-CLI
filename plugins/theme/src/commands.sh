# Theme command handlers.

_theme_current_name() {
    theme_load_state
    printf '%s\n' "$AIR_THEME_CURRENT"
}

_theme_renderer_name() {
    theme_load_state
    printf '%s\n' "$AIR_THEME_RENDERER"
}

_theme_apply() {
    local requested="$1"
    local renderer="${2:-$(_theme_renderer_name)}"

    theme_load_config
    theme_apply "$requested" "$renderer"
}

theme_cmd_list() {
    local renderer theme

    renderer="$(_theme_renderer_name)"
    {
        printf 'THEME\tDESCRIPTION\tCONFIG\n'
        for theme in $(theme_names "$renderer"); do
            printf '%s\t%s\t%s\n' \
                "$theme" \
                "$(theme_theme_summary "$renderer" "$theme")" \
                "$(theme_config_path_for "$theme" "$renderer")"
        done
    } | ui table
}

theme_cmd_current() {
    local theme renderer segment

    theme="$(_theme_current_name)"
    renderer="$(_theme_renderer_name)"
    theme_load_config

    if [ "${AIR_THEME_PATH_SEGMENT_MAX:-18}" = "0" ]; then
        segment="off"
    else
        segment="${AIR_THEME_PATH_SEGMENT_MAX:-18}"
    fi

    ui kv "当前主题" "${AIR_THEME:-$theme}"
    ui kv "默认主题" "$theme"
    ui kv "渲染器" "$renderer"
    ui kv "设置文件" "$(theme_settings_path)"
    ui kv "路径设置" "depth=${AIR_THEME_PATH_DEPTH:-3} segment=$segment"
    ui kv "渲染配置" "${STARSHIP_CONFIG:-$(theme_config_path_for "$theme" "$renderer")}"
    ui kv "插件状态" "$(plugin_is_enabled theme && printf enabled || printf disabled)"
}

theme_cmd_use() {
    local requested="${1:-}" theme renderer

    renderer="$(_theme_renderer_name)"
    theme="$(theme_name "$requested" "$renderer")" || {
        log_error "air theme: 未知主题: $requested"
        log_warn "运行 air theme list 查看可用主题。"
        return 1
    }

    _theme_apply "$theme" "$renderer" || return 1
    log_success "已切换当前会话主题: $theme"
}

theme_cmd_save() {
    local requested="${1:-}" theme renderer

    renderer="$(_theme_renderer_name)"
    theme="$(theme_name "$requested" "$renderer")" || {
        log_error "air theme: 未知主题: $requested"
        log_warn "运行 air theme list 查看可用主题。"
        return 1
    }

    _theme_apply "$theme" "$renderer" || return 1
    theme_save_state "$theme" "$renderer"
    log_success "已保存默认主题: $theme"
}

theme_cmd_renderer() {
    plugin_dispatch_group_command theme renderer "$@"
}

theme_renderer_cmd_list() {
    local renderer manifest

    {
        printf 'RENDERER\tDESCRIPTION\tSTATUS\n'
        for renderer in $(theme_renderer_names); do
            manifest="$(theme_renderer_manifest_path "$renderer")"
            printf '%s\t%s\t%s\n' \
                "$renderer" \
                "$(plugin_toml_value "$manifest" summary 2>/dev/null || printf '-')" \
                "$(theme_renderer_exists "$renderer" && printf ready || printf missing)"
        done
    } | ui table
}

theme_renderer_cmd_current() {
    ui kv "当前 renderer" "$(_theme_renderer_name)"
}

theme_renderer_cmd_use() {
    local renderer="${1:-}" theme

    if ! theme_renderer_exists "$renderer"; then
        log_error "air theme renderer: 未知 renderer: $renderer"
        return 1
    fi

    theme="$(_theme_current_name)"
    theme_load_config
    theme_apply "$theme" "$renderer" || return 1
    theme_save_state "$theme" "$renderer"
    log_success "已设置 theme renderer: $renderer"
}

theme_renderer_cmd_status() {
    theme_renderer_call "$(_theme_renderer_name)" status
}

theme_renderer_cmd_install() {
    theme_renderer_call "$(_theme_renderer_name)" install
}

theme_renderer_cmd_update() {
    theme_renderer_call "$(_theme_renderer_name)" update
}

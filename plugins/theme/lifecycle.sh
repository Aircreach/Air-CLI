plugin_preflight() {
    local purpose="${1:-enable}"
    local renderer theme

    theme_load_state
    theme_load_config
    renderer="$AIR_THEME_RENDERER"
    theme="$AIR_THEME_CURRENT"

    if ! _theme_renderer_exists "$renderer"; then
        ui check-item error "theme renderer" "Unknown renderer: $renderer"
        return 1
    fi
    theme_apply "$theme" "$renderer" || {
        ui check-item error "theme" "Theme cannot be applied: $theme"
        return 1
    }
    if _theme_renderer_call "$renderer" usable >/dev/null 2>&1; then
        ui check-item ok "theme renderer" "$renderer is usable."
        return 0
    fi
    if [ "$purpose" = "enable" ] && plugin_is_setup theme; then
        ui check-item error "theme renderer" "$renderer is not usable. Run air theme renderer install before enabling."
        return 1
    fi
    if command -v curl >/dev/null 2>&1; then
        ui check-item warning "theme renderer" "$renderer is not installed yet; setup can install it."
        return 0
    fi
    ui check-item error "theme renderer" "$renderer is not usable and curl is unavailable for install."
    return 1
}

plugin_setup() {
    local renderer theme

    theme_load_state
    theme_load_config
    renderer="$AIR_THEME_RENDERER"
    theme="$AIR_THEME_CURRENT"

    _theme_renderer_call "$renderer" ensure || return 1
    theme_apply "$theme" "$renderer" || return 1
    theme_save_state "$theme" "$renderer"
    log success "Theme plugin setup completed."
}

plugin_enable() {
    local renderer theme

    theme_load_state
    theme_load_config
    renderer="$AIR_THEME_RENDERER"
    theme="$AIR_THEME_CURRENT"

    theme_apply "$theme" "$renderer" || return 1
    theme_save_state "$theme" "$renderer"
    _theme_renderer_call "$renderer" init_current_shell >/dev/null 2>&1 || true
    log success "Theme plugin enabled."
}

plugin_disable() {
    local renderer

    theme_load_state
    renderer="$AIR_THEME_RENDERER"

    if _theme_renderer_exists "$renderer"; then
        _theme_renderer_call "$renderer" disable_current_shell >/dev/null 2>&1 || true
    fi

    log success "Theme plugin disabled."
}

plugin_reset() {
    local renderer

    theme_load_state
    renderer="$AIR_THEME_RENDERER"

    if _theme_renderer_exists "$renderer"; then
        _theme_renderer_call "$renderer" reset || return 1
        _theme_renderer_call "$renderer" disable_current_shell >/dev/null 2>&1 || true
    fi

    rm -rf "$(theme_data_dir)"
    log success "Theme plugin reset completed."
}

plugin_status() {
    local enabled="disabled"
    local setup="missing"

    plugin_is_enabled theme && enabled="enabled"
    plugin_is_setup theme && setup="ready"
    theme_load_state
    ui kv "插件" "theme"
    ui kv "状态" "$enabled"
    ui kv "Setup" "$setup"
    ui kv "主题" "$AIR_THEME_CURRENT"
    ui kv "渲染器" "$AIR_THEME_RENDERER"
    ui kv "配置" "$(theme_settings_path)"
    ui kv "状态文件" "$(theme_state_path)"
}

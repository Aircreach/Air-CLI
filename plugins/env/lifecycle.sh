plugin_setup() {
    env_setup_files || return 1
    log_success "Env plugin setup completed."
}

env_enable_builtin_if_present() {
    local name="$1" target="$2"

    env_capability_exists "$name" || env_add_builtin_capability "$name" || return 1
    env_target_add_capability "$target" "$name" || return 1
}

env_enable_detected_builtins() {
    env_enable_builtin_if_present local-bin bashrc || return 1
    env_enable_builtin_if_present local-bin bash-env || return 1

    if [ -d "${PYENV_ROOT:-$HOME/.pyenv}" ]; then
        env_enable_builtin_if_present pyenv bashrc || return 1
        env_enable_builtin_if_present pyenv bash-env || return 1
    fi

    if [ -d "${NVM_DIR:-$HOME/.nvm}" ]; then
        env_enable_builtin_if_present nvm bashrc || return 1
        env_enable_builtin_if_present nvm bash-env || return 1
    fi
}

plugin_enable() {
    env_setup_files || return 1
    env_enable_detected_builtins || return 1
    env_enable_inject_target bash-env || return 1
    env_runtime_apply_current_shell || return 1
    log_success "Env plugin enabled. Detected runtimes were activated and loaded into this shell."
}

plugin_disable() {
    log_success "Env plugin disabled. Capability state and shell markers were kept, but runtime injection is gated off."
}

plugin_reset() {
    env_remove_shell_markers || true
    rm -rf "$(plugin_config_dir env)" "$(plugin_state_dir env)" "$(plugin_runtime_dir env)" "$(plugin_cache_dir env)"
    log_success "Env plugin reset completed."
}

plugin_status() {
    local target capability

    ui kv "插件" "env"
    ui kv "状态" "$(plugin_is_enabled env && printf enabled || printf disabled)"
    ui kv "Setup" "$(plugin_is_setup env && printf ready || printf missing)"
    ui kv "状态目录" "$(env_data_dir)"
    ui kv "bashrc runtime" "$(env_bashrc_runtime_path)"
    ui kv "bash-env inject" "$(env_inject_is_enabled bash-env && printf enabled || printf disabled)"
    ui kv "bash-env runtime" "$(env_bash_env_path)"
    for target in $(env_target_names); do
        ui kv "$target targets" "$(env_target_capabilities "$target" | paste -sd ',' - 2>/dev/null || true)"
    done
    for capability in $(env_capability_names); do
        ui kv "能力" "$capability ($(env_capability_kind "$capability")) -> $(env_capability_targets "$capability" | paste -sd ',' -)"
    done
}

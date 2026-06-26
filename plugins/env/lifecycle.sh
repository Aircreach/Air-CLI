plugin_setup() {
    env_setup_files || return 1
    log_success "Env plugin setup completed."
}

plugin_enable() {
    env_setup_files || return 1
    log_success "Env plugin enabled. Install built-ins with 'air env add <name>', activate targets, then opt into injection with 'air env inject enable bash-env'."
}

plugin_disable() {
    log_success "Env plugin disabled. Capability state and shell markers were kept, but runtime injection is gated off."
}

plugin_reset() {
    env_remove_shell_markers || true
    rm -rf "$(env_data_dir)"
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

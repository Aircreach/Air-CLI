# Air plugin config command.

_air_config_help() {
    cat <<'EOF'
air config - 编辑插件配置

用法:
  air config --help
  air config --path <插件>
  air config <插件>

说明:
  编辑器优先级: $VISUAL -> $EDITOR -> nano -> vi
EOF
}

_air_config_editor() {
    if [ -n "${VISUAL:-}" ]; then
        printf '%s\n' "$VISUAL"
    elif [ -n "${EDITOR:-}" ]; then
        printf '%s\n' "$EDITOR"
    elif command -v nano >/dev/null 2>&1; then
        printf 'nano\n'
    elif command -v vi >/dev/null 2>&1; then
        printf 'vi\n'
    else
        return 1
    fi
}

air_config() {
    local command="${1:-}"
    local plugin editor config

    case "$command" in
        -h|--help|'')
            _air_config_help
            ;;
        --path)
            plugin="${2:-}"
            plugin_ensure_settings "$plugin" || {
                log_error "air config: 未知插件: $plugin"
                return 1
            }
            plugin_settings_path "$plugin"
            ;;
        *)
            plugin="$command"
            plugin_ensure_settings "$plugin" || {
                log_error "air config: 未知插件: $plugin"
                return 1
            }
            config="$(plugin_settings_path "$plugin")"
            editor="$(_air_config_editor)" || {
                log_error "air config: 未找到可用编辑器，请设置 VISUAL 或 EDITOR。"
                return 1
            }
            "$editor" "$config"
            ;;
    esac
}

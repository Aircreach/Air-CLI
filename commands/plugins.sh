# Air plugin command.

_air_plugin_help() {
    cat <<'EOF'
air plugin - 查看 Air 插件状态

用法:
  air plugin
  air plugin --help
  air plugin status <插件>
  air plugin check <插件>
  air plugin scaffold <插件>

说明:
  air plugins 仍可作为 air plugin 的兼容入口。
EOF
}

_air_plugin_table() {
    local plugin status setup structure risk version description settings

    {
        printf 'PLUGIN\tSTATUS\tSETUP\tSTRUCTURE\tRISK\tVERSION\tDESCRIPTION\tSETTINGS\n'
        for plugin in $(plugin_names); do
            if plugin_is_enabled "$plugin"; then
                status="enabled"
            else
                status="disabled"
            fi

            if plugin_is_setup "$plugin"; then
                setup="ready"
            else
                setup="missing"
            fi

            structure="$(plugin_structure_health "$plugin")"
            risk="$(plugin_setup_risk "$plugin")"
            version="$(plugin_meta_value "$plugin" version 2>/dev/null || printf '-')"
            description="$(plugin_meta_value "$plugin" description 2>/dev/null || printf '-')"
            settings="$(plugin_settings_path "$plugin")"
            [ -e "$settings" ] || settings="-"

            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$plugin" "$status" "$setup" "$structure" "$risk" "$version" "$description" "$settings"
        done
    } | ui table
}

air_plugin() {
    local command="${1:-}"
    local plugin

    case "$command" in
        -h|--help)
            _air_plugin_help
            ;;
        '')
            _air_plugin_table
            ;;
        status)
            plugin="${2:-}"
            if [ -z "$plugin" ]; then
                log error "air plugin status: 缺少插件名"
                return 1
            fi
            plugin_status "$plugin"
            ;;
        check)
            plugin="${2:-}"
            if [ -z "$plugin" ]; then
                log error "air plugin check: 缺少插件名"
                return 1
            fi
            plugin_check "$plugin"
            ;;
        scaffold)
            plugin="${2:-}"
            if [ -z "$plugin" ]; then
                log error "air plugin scaffold: 缺少插件名"
                return 1
            fi
            plugin_scaffold "$plugin"
            ;;
        *)
            log error "air plugin: 未知命令: $command"
            log warn "运行 air plugin --help 查看用法。"
            return 1
            ;;
    esac
}

air_plugins() {
    air_plugin "$@"
}

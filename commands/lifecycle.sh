# Air plugin lifecycle commands.

_air_lifecycle_help() {
    local command="$1"

    cat <<EOF
air $command - ${command} 插件

用法:
  air $command <插件>

可用插件:
$(plugin_names | sed 's/^/  /')
EOF
}

air_enable() {
    local plugin="${1:-}"

    case "$plugin" in
        -h|--help|'')
            _air_lifecycle_help enable
            ;;
        *)
            plugin_enable "$plugin"
            ;;
    esac
}

air_disable() {
    local plugin="${1:-}"

    case "$plugin" in
        -h|--help|'')
            _air_lifecycle_help disable
            ;;
        *)
            plugin_disable "$plugin"
            ;;
    esac
}

air_reset() {
    local plugin="${1:-}"

    case "$plugin" in
        -h|--help|'')
            _air_lifecycle_help reset
            ;;
        *)
            plugin_reset "$plugin"
            ;;
    esac
}

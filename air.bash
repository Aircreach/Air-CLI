# Aircreach local command system.

_air_bootstrap_home() {
    local source="${BASH_SOURCE[0]:-}"

    if [ -n "${AIR_HOME:-}" ]; then
        printf '%s\n' "$AIR_HOME"
        return 0
    fi
    if [ -n "$source" ] && [ -r "$source" ]; then
        (cd "$(dirname "$source")" 2>/dev/null && pwd -P) && return 0
    fi
    printf '%s\n' "$HOME/.local/share/air"
}

AIR_HOME="$(_air_bootstrap_home)"
AIR_STATE_HOME="${AIR_STATE_HOME:-$AIR_HOME/state}"
AIR_CONFIG_HOME="${AIR_CONFIG_HOME:-$AIR_STATE_HOME}"
export AIR_HOME AIR_STATE_HOME AIR_CONFIG_HOME

air_home() {
    printf '%s\n' "$AIR_HOME"
}

air_state_home() {
    printf '%s\n' "$AIR_STATE_HOME"
}

air_config_home() {
    printf '%s\n' "$AIR_CONFIG_HOME"
}

_air_source_dir() {
    local dir="$1"
    local file

    [ -d "$dir" ] || return 0
    for file in "$dir"/*.sh "$dir"/*.bash; do
        [ -r "$file" ] && . "$file"
    done
}

_air_source_ui() {
    # shellcheck disable=SC1090
    [ -r "$AIR_HOME/ui/ui.sh" ] && . "$AIR_HOME/ui/ui.sh"
}

_air_source_libs() {
    _air_source_dir "$AIR_HOME/lib/output"
    _air_source_dir "$AIR_HOME/lib"
}

_air_source_commands() {
    _air_source_dir "$AIR_HOME/commands"
    local command_dir

    for command_dir in "$AIR_HOME"/commands/*; do
        [ -d "$command_dir" ] && _air_source_dir "$command_dir"
    done
}

_air_help() {
    cat <<'EOF'
air - Aircreach 的本地命令入口

用法:
  air --help
  air [--yes] [--non-interactive] [--plain] <命令> [参数]
  air <命令> [参数]

全局选项:
  --yes             接受 warning 级确认
  --non-interactive 禁止交互输入，缺少必填值时报错
  --plain           关闭颜色和装饰输出

可用命令:
  ui        查看和配置 Air 原生 CLI UI
  plugin    查看插件状态
  enable    启用插件
  disable   禁用插件
  reset     重置插件
  config    编辑插件配置
EOF
    plugin_command_help 2>/dev/null || true
}

air() {
    local command
    local plugin
    local AIR_UI_CLI=1
    export AIR_UI_CLI

    air_parse_global_options "$@"
    set -- "${AIR_PARSED_ARGS[@]}"
    command="${1:-}"

    case "$command" in
        -h|--help|'')
            _air_help
            ;;
        plugin)
            shift
            air_plugin "$@"
            ;;
        ui)
            shift
            air_ui "$@"
            ;;
        plugins)
            shift
            air_plugin "$@"
            ;;
        enable)
            shift
            air_enable "$@"
            ;;
        disable)
            shift
            air_disable "$@"
            ;;
        reset)
            shift
            air_reset "$@"
            ;;
        config)
            shift
            air_config "$@"
            ;;
        *)
            plugin="$(plugin_for_command "$command" 2>/dev/null || true)"
            if [ -n "$plugin" ]; then
                shift
                plugin_run_command "$plugin" "$@"
                return "$?"
            fi
            log_error "air: 未知命令: $command"
            log_warn "运行 air --help 查看可用命令。"
            return 1
            ;;
    esac
}

air_init() {
    local shell="${1:-bash}"
    local plugin

    case "$shell" in
        bash) ;;
        *)
            log_error "air init: 暂不支持 shell: $shell"
            return 1
            ;;
    esac

    for plugin in $(enabled_plugins); do
        plugin_init "$plugin" "$shell"
    done
}

_air_source_ui
_air_source_libs
_air_source_commands

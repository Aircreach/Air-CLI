# Theme runtime initialization.

runtime_init() {
    local shell="${1:-bash}"

    case "$shell" in
        bash) ;;
        *) return 0 ;;
    esac

    theme_load_state
    theme_load_config
    _theme_renderer_call "$AIR_THEME_RENDERER" usable >/dev/null 2>&1 || return 0
    theme_apply "$AIR_THEME_CURRENT" "$AIR_THEME_RENDERER" || return 0
    _theme_renderer_call "$AIR_THEME_RENDERER" init "$shell" || return 0
}

# Theme shared helpers.

theme_name() {
    local theme="$1" renderer="${2:-${AIR_THEME_RENDERER:-starship}}"

    [ -n "$theme" ] || return 1
    [ -r "$(theme_theme_manifest_path "$renderer" "$theme")" ] || return 1
    printf '%s\n' "$theme"
}

theme_names() {
    local renderer="${1:-${AIR_THEME_RENDERER:-starship}}" dir file id

    dir="$(theme_theme_root "$renderer")"
    [ -d "$dir" ] || return 0
    for file in "$dir"/*.theme.toml; do
        [ -r "$file" ] || continue
        id="$(plugin_toml_value "$file" id 2>/dev/null || true)"
        [ -n "$id" ] && printf '%s\n' "$id"
    done
}

theme_theme_root() {
    local renderer="$1"

    printf '%s\n' "$(theme_renderer_dir "$renderer")/themes"
}

theme_theme_manifest_path() {
    local renderer="$1" theme="$2"

    printf '%s\n' "$(theme_theme_root "$renderer")/$theme.theme.toml"
}

theme_theme_summary() {
    local renderer="$1" theme="$2"

    plugin_toml_value "$(theme_theme_manifest_path "$renderer" "$theme")" summary 2>/dev/null || printf '-\n'
}

theme_config_path_for() {
    local theme="$1"
    local renderer="$2"
    local manifest config

    manifest="$(theme_theme_manifest_path "$renderer" "$theme")"
    config="$(plugin_toml_value "$manifest" config 2>/dev/null || printf '%s.toml' "$theme")"
    printf '%s\n' "$(theme_theme_root "$renderer")/$config"
}

theme_apply() {
    local requested="$1"
    local renderer="$2"
    local theme config_path

    theme="$(theme_name "$requested" "$renderer")" || return 1
    config_path="$(theme_config_path_for "$theme" "$renderer")"

    if [ ! -r "$config_path" ]; then
        log_error "air theme: 缺少配置文件: $config_path"
        return 1
    fi

    export AIR_THEME="$theme"
    export AIR_THEME_RENDERER="$renderer"
    export STARSHIP_CONFIG="$config_path"
}

# Theme renderer helpers.

theme_renderer_root() {
    plugin_meta_value theme renderers.path 2>/dev/null | sed "s#^#$(plugin_dir theme)/#"
}

theme_renderer_dir() {
    printf '%s\n' "$(theme_renderer_root)/$1"
}

theme_renderer_manifest_path() {
    printf '%s\n' "$(theme_renderer_dir "$1")/renderer.toml"
}

theme_renderer_names() {
    local dir

    [ -d "$(theme_renderer_root)" ] || return 0
    for dir in "$(theme_renderer_root)"/*; do
        [ -d "$dir" ] || continue
        [ -r "$dir/renderer.toml" ] || continue
        [ -r "$dir/renderer.sh" ] || continue
        printf '%s\n' "${dir##*/}"
    done
}

theme_renderer_exists() {
    local renderer="$1"

    [ -r "$(theme_renderer_dir "$renderer")/renderer.sh" ]
}

theme_renderer_source() {
    local renderer="$1"
    local renderer_file="$(theme_renderer_dir "$renderer")/renderer.sh"

    [ -r "$renderer_file" ] || return 1
    . "$renderer_file"
}

theme_renderer_call() {
    local renderer="$1"
    local action="$2"
    local function_name

    shift 2
    theme_renderer_source "$renderer" || {
        log_error "air theme renderer: 未知 renderer: $renderer"
        return 1
    }

    function_name="theme_${renderer}_${action}"
    if ! command -v "$function_name" >/dev/null 2>&1; then
        log_error "air theme renderer: renderer $renderer 不支持操作: $action"
        return 1
    fi

    "$function_name" "$@"
}

_theme_renderer_names() {
    theme_renderer_names "$@"
}

_theme_renderer_exists() {
    theme_renderer_exists "$@"
}

_theme_renderer_source() {
    theme_renderer_source "$@"
}

_theme_renderer_call() {
    theme_renderer_call "$@"
}

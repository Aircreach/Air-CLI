# Starship renderer for the Air theme plugin.

theme_starship_home() {
    theme_renderer_dir starship
}

theme_starship_bin() {
    printf '%s\n' "$(theme_starship_home)/bin/starship"
}

theme_starship_status() {
    local bin version

    bin="$(theme_starship_bin)"
    ui kv "renderer" "starship"
    ui kv "path" "$bin"

    if [ -x "$bin" ]; then
        version="$("$bin" --version 2>/dev/null | sed -n '1p')"
        if theme_starship_usable; then
            ui check-item ok "starship" "Renderer is usable."
            ui kv "status" "usable"
        else
            ui check-item warning "starship" "Renderer binary exists but cannot run."
            ui kv "status" "stale"
        fi
        ui kv "version" "${version:-unknown}"
    else
        ui check-item warning "starship" "Renderer binary is not installed."
        ui kv "status" "missing"
    fi
}

theme_starship_usable() {
    local bin

    bin="$(theme_starship_bin)"
    [ -x "$bin" ] || return 1
    "$bin" --version >/dev/null 2>&1
}

theme_starship_install() {
    local home

    home="$(theme_starship_home)"
    mkdir -p "$home/bin"

    if ! command -v curl >/dev/null 2>&1; then
        log_error "air theme renderer: 需要 curl 才能安装 starship。"
        return 1
    fi

    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$home/bin"
}

theme_starship_ensure() {
    if theme_starship_usable; then
        return 0
    fi

    log_warn "air theme: 未检测到托管 starship renderer，正在安装..."
    theme_starship_install
}

theme_starship_update() {
    theme_starship_install
}

theme_starship_reset() {
    rm -f "$(theme_starship_bin)"
}

_theme_starship_shorten_segment() {
    local segment="$1"
    local max="${AIR_THEME_PATH_SEGMENT_MAX:-18}"
    local ellipsis="${AIR_THEME_PATH_ELLIPSIS:-…}"
    local len keep left right

    [ "${AIR_THEME_PATH_SEGMENT_ENABLED:-1}" = "1" ] || {
        REPLY="$segment"
        return 0
    }

    [ "$max" -gt 0 ] 2>/dev/null || {
        REPLY="$segment"
        return 0
    }

    len="${#segment}"
    if [ "$len" -le "$max" ] || [ "$max" -lt 5 ]; then
        REPLY="$segment"
        return 0
    fi

    keep=$((max - ${#ellipsis}))
    [ "$keep" -gt 1 ] || keep=1
    left=$(((keep + 1) / 2))
    right=$((keep - left))
    REPLY="${segment:0:left}$ellipsis${segment:len-right:right}"
}

_theme_starship_format_dir() {
    local path="${1:-$PWD}"
    local home="${HOME%/}"
    local display rest depth segment output count total start i
    local -a parts selected

    depth="${AIR_THEME_PATH_DEPTH:-3}"
    case "$depth" in
        1|2|3) ;;
        *) depth=3 ;;
    esac

    if [ "$path" = "$home" ]; then
        display="${AIR_THEME_PATH_HOME:-~}"
    elif [ "${path#"$home"/}" != "$path" ]; then
        rest="${path#"$home"/}"
        display="$rest"
    else
        display="${path#/}"
    fi

    if [ "$display" != "${AIR_THEME_PATH_HOME:-~}" ]; then
        rest="$display"
        parts=()
        while [ -n "$rest" ]; do
            segment="${rest%%/*}"
            parts+=("$segment")
            if [ "$rest" = "$segment" ]; then
                break
            fi
            rest="${rest#*/}"
        done

        total="${#parts[@]}"
        start=$((total - depth))
        [ "$start" -lt 0 ] && start=0

        selected=()
        i="$start"
        while [ "$i" -lt "$total" ]; do
            if [ "${AIR_THEME_PATH_SEGMENT_ENABLED:-1}" = "1" ]; then
                _theme_starship_shorten_segment "${parts[i]}"
                selected+=("$REPLY")
            else
                selected+=("${parts[i]}")
            fi
            i=$((i + 1))
        done

        output=""
        count=0
        for segment in "${selected[@]}"; do
            if [ "$count" -eq 0 ]; then
                output="$segment"
            else
                output="$output/$segment"
            fi
            count=$((count + 1))
        done
        display="$output"
    fi

    REPLY="${AIR_THEME_PATH_ICON:-} $display"
}

_theme_starship_set_prompt_context() {
    local venv="${VIRTUAL_ENV:-}"
    local python_version=""
    local git_branch=""
    local secondary_icon="" secondary_text="" folded_icons=""

    venv="${VIRTUAL_ENV_PROMPT:-${venv##*/}}"
    venv="${venv#(}"
    venv="${venv%)}"

    set_prompt_env AIR_PROMPT_SECONDARY ""
    set_prompt_env AIR_PROMPT_FOLDED ""
    set_prompt_env AIR_PROMPT_DENSE_VENV ""
    set_prompt_env AIR_PROMPT_DENSE_PYTHON ""
    set_prompt_env AIR_PROMPT_DENSE_GIT ""
    _theme_starship_format_dir "$PWD"
    set_prompt_env AIR_PROMPT_DIR "$REPLY"

    if [ -n "${VIRTUAL_ENV:-}" ]; then
        secondary_icon=""
        secondary_text="$venv"
        set_prompt_env AIR_PROMPT_DENSE_VENV "$venv"
    fi

    if [ -n "${VIRTUAL_ENV:-}" ] || is_project "$PWD"; then
        python_version="$(version)" || python_version=""
        if [ -n "$python_version" ]; then
            set_prompt_env AIR_PROMPT_DENSE_PYTHON "$python_version"
        fi
    fi

    git_branch="$(branch "$PWD")" || git_branch=""
    if [ -n "$git_branch" ]; then
        set_prompt_env AIR_PROMPT_DENSE_GIT "$git_branch"
    fi

    if [ -z "$secondary_text" ]; then
        if [ -n "$git_branch" ]; then
            secondary_icon=""
            secondary_text="$git_branch"
            [ -n "$python_version" ] && folded_icons=""
        elif [ -n "$python_version" ]; then
            secondary_icon=""
            secondary_text="$python_version"
        fi
    else
        [ -n "$python_version" ] && folded_icons=""
        [ -n "$git_branch" ] && folded_icons="${folded_icons:+$folded_icons }"
    fi

    if [ -n "$secondary_text" ]; then
        set_prompt_env AIR_PROMPT_SECONDARY "$secondary_icon $secondary_text"
    else
        set_prompt_env AIR_PROMPT_SECONDARY ""
    fi

    if [ -n "$folded_icons" ]; then
        set_prompt_env AIR_PROMPT_FOLDED "$folded_icons"
    else
        set_prompt_env AIR_PROMPT_FOLDED ""
    fi
}

theme_starship_update_prompt_context() {
    _theme_starship_set_prompt_context
}

theme_starship_disable_current_shell() {
    unset starship_precmd_user_func
    unset STARSHIP_PROMPT_COMMAND
    unset STARSHIP_PREEXEC_READY
    unset STARSHIP_START_TIME
    unset STARSHIP_END_TIME
    unset STARSHIP_DURATION
    unset STARSHIP_CMD_STATUS
    unset STARSHIP_PIPE_STATUS
    unset STARSHIP_SESSION_KEY
    unset STARSHIP_SHELL
    unset AIR_THEME_STARSHIP_ACTIVE
    unset_prompt_envs \
        AIR_PROMPT_DIR \
        AIR_PROMPT_SECONDARY \
        AIR_PROMPT_FOLDED \
        AIR_PROMPT_DENSE_VENV \
        AIR_PROMPT_DENSE_PYTHON \
        AIR_PROMPT_DENSE_GIT

    if [ -n "${AIR_THEME_ORIGINAL_PROMPT_COMMAND+x}" ]; then
        PROMPT_COMMAND="$AIR_THEME_ORIGINAL_PROMPT_COMMAND"
    elif [ "${PROMPT_COMMAND:-}" = "starship_precmd" ]; then
        unset PROMPT_COMMAND
    fi

    if [ -n "${AIR_THEME_ORIGINAL_PS1+x}" ]; then
        PS1="$AIR_THEME_ORIGINAL_PS1"
    fi
    if [ -n "${AIR_THEME_ORIGINAL_PS2+x}" ]; then
        PS2="$AIR_THEME_ORIGINAL_PS2"
    fi
    if [ -n "${AIR_THEME_ORIGINAL_PS0+x}" ]; then
        PS0="$AIR_THEME_ORIGINAL_PS0"
    fi

    unset AIR_THEME
    unset AIR_THEME_RENDERER
    unset STARSHIP_CONFIG
}

theme_starship_init_current_shell() {
    local shell="${1:-bash}"

    theme_starship_init "$shell"
}

theme_starship_init() {
    local shell="${1:-bash}"

    case "$shell" in
        bash) ;;
        *) return 0 ;;
    esac

    local bin
    local init_script

    bin="$(theme_starship_bin)"
    if ! theme_starship_usable; then
        log_warn "air theme: starship renderer 未安装，请运行 air enable theme 或 air theme renderer install。"
        theme_starship_disable_current_shell >/dev/null 2>&1 || true
        return 0
    fi

    if [ -z "${AIR_THEME_STARSHIP_ACTIVE:-}" ]; then
        AIR_THEME_ORIGINAL_PS1="${PS1-}"
        AIR_THEME_ORIGINAL_PS2="${PS2-}"
        AIR_THEME_ORIGINAL_PS0="${PS0-}"
        AIR_THEME_ORIGINAL_PROMPT_COMMAND="${PROMPT_COMMAND-}"
        export AIR_THEME_STARSHIP_ACTIVE=1
    fi

    starship_precmd_user_func=theme_starship_update_prompt_context
    init_script="$("$bin" init bash 2>/dev/null)" || {
        log_warn "air theme: starship init failed; keeping the current prompt."
        theme_starship_disable_current_shell >/dev/null 2>&1 || true
        return 0
    }
    eval "$init_script" || {
        log_warn "air theme: starship init output failed; keeping the current prompt."
        theme_starship_disable_current_shell >/dev/null 2>&1 || true
        return 0
    }
}

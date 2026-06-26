# Theme prompt helpers.

set_prompt_env() {
    local name="$1"
    local value="${2:-}"

    if [ -n "$value" ]; then
        if [ "${!name-}" != "$value" ]; then
            export "$name=$value"
        fi
    else
        if [ -n "${!name+x}" ]; then
            unset "$name"
        fi
    fi
}

unset_prompt_envs() {
    local name

    for name in "$@"; do
        [ -n "${!name+x}" ] && unset "$name"
    done
}

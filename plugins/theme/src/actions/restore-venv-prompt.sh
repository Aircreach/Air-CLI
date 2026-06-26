# Restore the native Bash venv prefix after the theme renderer is disabled.

action_restore_venv_prompt() {
    local base_ps1 restore_ps1 prompt_name

    [ -n "${VIRTUAL_ENV:-}" ] || return 0
    [ -z "${VIRTUAL_ENV_DISABLE_PROMPT:-}" ] || return 0

    base_ps1="${PS1-}"
    restore_ps1="$base_ps1"
    prompt_name="${VIRTUAL_ENV_PROMPT:-${VIRTUAL_ENV##*/}}"
    prompt_name="${prompt_name#(}"
    prompt_name="${prompt_name%)}"

    case "$base_ps1" in
        "($prompt_name) "*)
            restore_ps1="${base_ps1#"($prompt_name) "}"
            ;;
        *)
            PS1="($prompt_name) $base_ps1"
            ;;
    esac

    _OLD_VIRTUAL_PS1="$restore_ps1"
}

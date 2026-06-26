# Product-neutral terminal helpers.

[ -n "${AIR_TERMINAL_LOADED:-}" ] && return 0
AIR_TERMINAL_LOADED=1

terminal_is_tty() {
    [ -t "${1:-1}" ]
}

terminal_stdin_is_tty() {
    terminal_is_tty 0
}

terminal_stdout_is_tty() {
    terminal_is_tty 1
}

terminal_stderr_is_tty() {
    terminal_is_tty 2
}

terminal_width() {
    local width

    width="$(tput cols 2>/dev/null || true)"
    case "$width" in
        ''|*[!0-9]*) width=80 ;;
    esac
    [ "$width" -lt 40 ] && width=40
    printf '%s\n' "$width"
}

terminal_supports_color() {
    terminal_stdout_is_tty || return 1
    [ -z "${NO_COLOR:-}" ] || return 1
    [ "${TERM:-}" != "dumb" ] || return 1
}

terminal_can_animate() {
    terminal_stderr_is_tty || return 1
    [ -z "${NO_COLOR:-}" ] || return 1
    [ "${TERM:-}" != "dumb" ] || return 1
}

terminal_sgr() {
    terminal_supports_color && printf '\033[%sm' "$1"
}

terminal_reset() {
    terminal_supports_color && printf '\033[0m'
}

terminal_color() {
    local code="$1"

    shift
    if terminal_supports_color; then
        printf '\033[%sm%s\033[0m' "$code" "$*"
    else
        printf '%s' "$*"
    fi
}

# Air structured logging helpers.

log_supports_color() {
    [ -t 1 ] && [ "${NO_COLOR:-}" = "" ] && [ "${AIR_PLAIN:-0}" != "1" ]
}

log_color() {
    local code="$1"

    shift
    if log_supports_color; then
        printf '\033[%sm%s\033[0m' "$code" "$*"
    else
        printf '%s' "$*"
    fi
}

log() {
    local level="${1:-info}"
    local label color stream

    shift || true
    case "$level" in
        info)
            label="info"
            color=36
            stream=1
            ;;
        success|ok)
            label="ok"
            color=32
            stream=1
            ;;
        warn|warning)
            label="warn"
            color=33
            stream=2
            ;;
        error|err)
            label="error"
            color=31
            stream=2
            ;;
        *)
            label="info"
            color=36
            stream=1
            set -- "$level" "$@"
            ;;
    esac

    if [ "$stream" = "2" ]; then
        {
            log_color "$color" "$label"
            printf ' %s\n' "$*"
        } >&2
    else
        log_color "$color" "$label"
        printf ' %s\n' "$*"
    fi
}

log_info() {
    log info "$@"
}

log_success() {
    log success "$@"
}

log_warn() {
    log warn "$@"
}

log_error() {
    log error "$@"
}

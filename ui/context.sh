# Air CLI interaction context.

air_ui_context_defaults() {
    AIR_YES="${AIR_YES:-0}"
    AIR_NON_INTERACTIVE="${AIR_NON_INTERACTIVE:-0}"
    AIR_PLAIN="${AIR_PLAIN:-0}"
    export AIR_YES AIR_NON_INTERACTIVE AIR_PLAIN
}

air_parse_global_options() {
    AIR_PARSED_ARGS=()
    air_ui_context_defaults

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --yes|-y)
                AIR_YES=1
                export AIR_YES
                shift
                ;;
            --non-interactive)
                AIR_NON_INTERACTIVE=1
                export AIR_NON_INTERACTIVE
                shift
                ;;
            --plain)
                AIR_PLAIN=1
                NO_COLOR=1
                export AIR_PLAIN NO_COLOR
                shift
                ;;
            --)
                shift
                while [ "$#" -gt 0 ]; do
                    AIR_PARSED_ARGS+=("$1")
                    shift
                done
                break
                ;;
            *)
                while [ "$#" -gt 0 ]; do
                    AIR_PARSED_ARGS+=("$1")
                    shift
                done
                break
                ;;
        esac
    done
}

ui_is_plain() {
    [ "${AIR_PLAIN:-0}" = "1" ] || [ -n "${NO_COLOR:-}" ]
}

ui_is_interactive() {
    [ "${AIR_NON_INTERACTIVE:-0}" != "1" ] && [ -t 0 ]
}

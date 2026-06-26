# Air UI data components.

ui_kv() {
    if [ "${1:-}" = "example" ]; then
        ui_kv "mode" "helper"
        ui_kv "renderer" "starship"
        ui_kv "status" "ready"
        return 0
    fi

    local key="$1" value="$2" padding

    padding=$((14 - ${#key} - 1))
    [ "$padding" -lt 1 ] && padding=1
    printf '  '
    ui_color "$AIR_UI_COLOR_MUTED" "$key:"
    printf '%*s' "$padding" ''
    ui_style_value "$value"
    printf '\n'
}

ui_table() {
    if [ "${1:-}" = "example" ]; then
        {
            printf 'NAME\tSTATUS\tNOTES\n'
            printf 'basic\tready\tBash fallback\n'
            printf 'helper\tenabled\tOptional command renderer\n'
            printf 'plain\tdisabled\tDecoration-free fallback\n'
        } | ui_table
        return 0
    fi

    local color=0

    ui_supports_color && color=1
    awk -v color="$color" \
        -v header_color="$AIR_UI_COLOR_HEADER" \
        -v muted_color="$AIR_UI_COLOR_MUTED" \
        -v ok_color="$AIR_UI_COLOR_OK" \
        -v warning_color="$AIR_UI_COLOR_WARNING" \
        -v error_color="$AIR_UI_COLOR_ERROR" \
        -v hint_color="$AIR_UI_COLOR_HINT" '
        function paint(code, value) {
            if (color == 1) {
                return sprintf("\033[%sm%s\033[0m", code, value)
            }
            return value
        }
        function style_cell(value, row) {
            if (row == 1) {
                return paint(header_color, value)
            }
            if (value == "enabled" || value == "ready" || value == "ok" || value == "success" || value == "usable" || value == "installed" || value == "passed" || value == "helper") {
                return paint(ok_color, value)
            }
            if (value == "disabled" || value == "missing" || value == "medium" || value == "warn" || value == "warning" || value == "stale" || value == "partial" || value == "skipped" || value == "basic" || value == "plain") {
                return paint(warning_color, value)
            }
            if (value == "high" || value == "destructive" || value == "failed" || value == "error" || value == "blocked" || value == "unusable" || value == "denied") {
                return paint(error_color, value)
            }
            if (value == "focus" || value == "dense" || value == "spacious" || value == "starship") {
                return paint(hint_color, value)
            }
            return value
        }
        BEGIN {
            FS = "\t"
            rows = 0
        }
        {
            rows++
            for (i = 1; i <= NF; i++) {
                cell[rows, i] = $i
                if (length($i) > width[i]) {
                    width[i] = length($i)
                }
            }
            if (NF > cols) {
                cols = NF
            }
        }
        END {
            for (r = 1; r <= rows; r++) {
                printf "  "
                for (c = 1; c <= cols; c++) {
                    value = cell[r, c]
                    styled = style_cell(value, r)
                    if (c < cols) {
                        printf "%s%*s  ", styled, width[c] - length(value), ""
                    } else {
                        printf "%s", styled
                    }
                }
                printf "\n"
                if (r == 1) {
                    printf "  "
                    for (c = 1; c <= cols; c++) {
                        line = ""
                        for (i = 0; i < width[c]; i++) {
                            line = line "-"
                        }
                        line = paint(muted_color, line)
                        if (c < cols) {
                            printf "%s  ", line
                        } else {
                            printf "%s", line
                        }
                    }
                    printf "\n"
                }
            }
        }
    '
}

ui_list() {
    local item

    if [ "${1:-}" = "example" ]; then
        ui_list "Use **bold** for the current thing" "Keep hints [[muted]]" "Return machine values on stdout"
        return 0
    fi

    if [ "$#" -gt 0 ]; then
        for item in "$@"; do
            printf '  - '
            ui_text "$item"
        done
    elif [ ! -t 0 ]; then
        while IFS= read -r item; do
            printf '  - '
            ui_text "$item"
        done
    fi
}

ui_summary() {
    local title="${1:-Summary}"

    if [ "$title" = "example" ]; then
        ui_summary "Summary" "mode" "helper" "interactive" "yes" "plain" "no"
        return 0
    fi

    shift || true
    ui title "$title"
    while [ "$#" -gt 1 ]; do
        ui kv "$1" "$2"
        shift 2
    done
}

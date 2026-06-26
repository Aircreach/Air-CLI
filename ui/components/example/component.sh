# Air UI component example registry.

ui_example_components() {
    cat <<'EOF'
text
markdown
panel
layout
effects
overlay
badge
block
check-item
log
input
password
select
multiselect
confirm
table
kv
summary
list
spinner
task
progress
code
hr
marker
EOF
}

ui_example_select_component() {
    local options="" component

    while IFS= read -r component; do
        [ -n "$component" ] || continue
        options="${options}${options:+
}${component}	${component}"
    done <<EOF
$(ui_example_components)
EOF
    ui select --prompt "Component example" --style menu --option "$options"
}

ui_example_all_static() {
    ui title "Air UI Component Examples"
    printf '  '
    ui_badge "plain safe" done
    printf ' '
    ui_badge "component params" hint
    printf ' '
    ui_badge "helper optional" warning
    printf '\n'
    ui spacer
    ui text example
    ui hr example
    ui badge example
    ui block example
    ui check-item example
    ui log example
    ui panel example
    ui markdown example
    ui layout example
    ui overlay example
    ui input example
    ui password example
    ui select example
    ui multiselect example
    ui confirm example
    ui table example
    ui kv example
    ui summary example
    ui list example
    ui spinner example
    ui task example
    ui code example
    ui progress --label "transfer" --bar block --spinner braille --width 20 --current 65 --total 100
    ui effects shimmer --label "Parsing data" --width 14
    ui effects gradient --text "Air UI"
    ui effects heatmap --label "load" --values "1 2 4 6 8 10"
    ui marker done
    printf ' '
    ui marker current
    printf ' '
    ui marker pending
    printf '\n'
}

ui_example_run_component() {
    local component="$1" static="${2:-0}"

    case "$component" in
        all)
            ui_example_all_static
            ;;
        progress)
            if [ "$static" = "1" ]; then
                ui progress --label "transfer" --bar block --spinner braille --width 20 --current 65 --total 100
            else
                ui progress example --label "transfer" --bar block --spinner braille --width 20
            fi
            ;;
        marker)
            ui title "Marker Example"
            printf '  '
            ui marker done
            printf ' done\n  '
            ui marker current
            printf ' current\n  '
            ui marker pending
            printf ' pending\n  '
            ui marker warn
            printf ' warning\n  '
            ui marker error
            printf ' error\n'
            ;;
        text|markdown|panel|layout|effects|overlay|badge|block|check-item|log|input|password|select|multiselect|confirm|table|kv|summary|list|spinner|task|code|hr)
            ui "$component" example
            ;;
        *)
            ui check-item error "ui example" "Unknown component: $component"
            return 1
            ;;
    esac
}

ui_example() {
    local component="" static=0

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --static|-s)
                static=1
                shift
                ;;
            all)
                component=all
                shift
                ;;
            --*)
                ui check-item error "ui example" "Unknown option: $1"
                return 1
                ;;
            *)
                component="$1"
                shift
                ;;
        esac
    done

    if [ -z "$component" ]; then
        if ui_is_interactive && [ "$static" != "1" ]; then
            component="$(ui_example_select_component)" || return 1
        else
            component=all
        fi
    fi

    ui_example_run_component "$component" "$static"
}

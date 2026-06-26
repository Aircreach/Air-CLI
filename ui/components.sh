# Air UI component registry and loader.

_air_ui_component_source() {
    local file="$1"

    [ -r "$file" ] && . "$file"
}

_AIR_UI_ROOT="$(ui_home)"
_air_ui_component_source "$(ui_air_home)/lib/terminal.sh"
_air_ui_component_source "$_AIR_UI_ROOT/components/text/component.sh"
_air_ui_component_source "$_AIR_UI_ROOT/layout/component.sh"
_air_ui_component_source "$_AIR_UI_ROOT/blocks.sh"
_air_ui_component_source "$_AIR_UI_ROOT/components/marker/component.sh"
_air_ui_component_source "$_AIR_UI_ROOT/components/interactive/component.sh"
_air_ui_component_source "$_AIR_UI_ROOT/components/progress/component.sh"
_air_ui_component_source "$_AIR_UI_ROOT/effects/component.sh"
_air_ui_component_source "$_AIR_UI_ROOT/components/overlay/component.sh"
_air_ui_component_source "$_AIR_UI_ROOT/components/data/component.sh"
_air_ui_component_source "$_AIR_UI_ROOT/components/workflow/component.sh"
_air_ui_component_source "$_AIR_UI_ROOT/components/flow/component.sh"
_air_ui_component_source "$_AIR_UI_ROOT/components/example/component.sh"
unset _AIR_UI_ROOT

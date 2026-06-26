# Air UI data component shim.

_air_ui_data_source="$(ui_path data.sh)"
[ -r "$_air_ui_data_source" ] && . "$_air_ui_data_source"
unset _air_ui_data_source

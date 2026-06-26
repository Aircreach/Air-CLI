# Air UI workflow component shim.

_air_ui_workflow_source="$(ui_path workflow.sh)"
[ -r "$_air_ui_workflow_source" ] && . "$_air_ui_workflow_source"
unset _air_ui_workflow_source

# Legacy compatibility shim. The real UI subsystem lives in $AIR_HOME/ui.

if [ -z "${AIR_UI_LOADED:-}" ]; then
    # shellcheck disable=SC1090
    . "${AIR_HOME:-$HOME/.local/share/air}/ui/ui.sh"
fi

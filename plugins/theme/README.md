# Theme

Air plugin for interactive prompt themes and renderer integration.

Framework contract files live at the plugin root. Theme implementation lives in `src/`, renderer packages live in `src/renderers/`, default configuration lives in root `settings.sh`, and user state stays under `$AIR_STATE_HOME/plugins/theme`.

Renderer startup is guarded: if the managed Starship binary is missing or stale, Air keeps the current prompt and reports the issue through `air theme renderer status` and `air plugin check theme`.

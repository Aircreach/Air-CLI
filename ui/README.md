# Air UI

Air UI is a native Air subsystem, not a plugin. Users configure and inspect it
with `air ui ...`; core commands and plugins call the Bash `ui ...` API.
Air also provides `air_home`, `air_state_home`, `ui_home`, `ui_state_home`,
and `ui_path` as the canonical path-resolution helpers.

Start here:

- `ui/docs/README.md`: architecture and command surface
- `ui/docs/components.md`: component APIs and examples
- `ui/docs/examples.md`: `air ui example` behavior
- `ui/docs/layout.md`: layout, wizard, rails, and viewports
- `ui/docs/terminal-design.md`: terminal capability boundaries and visual rules
- `ui/docs/plugin-usage.md`: how plugins should consume Air UI

Helper UI is optional. The basic Bash UI is the default and remains the
startup-safe fallback.

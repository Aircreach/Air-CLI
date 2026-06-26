# Air UI Docs

Air UI is the product-facing terminal UI layer for Air. It owns interaction,
status blocks, guided flows, component examples, helper-mode state, helper
adapter behavior, and themeable display tokens.

Native command surface:

```bash
air ui
air ui status
air ui components
air ui example [component] [--static|-s]
air ui preview
air ui check
air ui run <flow.toml>
air ui enable --helper
air ui disable --helper
```

Implementation shape:

- `ui/components/<component>/`: first-class component entrypoints and examples.
- `ui/layout/`: layout primitives, split panes, wizard shell, step rail, viewport.
- `ui/effects/`: explicit frame-rendered motion.
- `ui/docs/`: documentation; component folders do not carry individual READMEs.
- `lib/terminal.sh`: product-neutral terminal primitives.
- `air_home`/`air_config_home`/`air_state_home`/`air_runtime_home`: Air
  framework and user-data roots.
- `ui_home`/`ui_config_home`/`ui_state_home`/`ui_runtime_home`/`ui_path`:
  UI-local path resolution.

Fallback rules:

- `--plain` or `NO_COLOR`: plain Bash output.
- non-interactive stdin: no blocking prompts.
- helper missing or disabled: Bash component implementation.
- shell startup: no helper, flow, Docker, download, or build probing.

Path rules:

- Runtime code may resolve absolute paths through `ui_path`.
- UI settings belong under `ui_config_home`.
- Runtime helper binaries and downloaded toolchains belong under `ui_runtime_home`.
- Persisted state should prefer logical values and paths under `ui_state_home`.
- Avoid baking installation-specific absolute paths into generated config when a
  relative or logical reference is sufficient.

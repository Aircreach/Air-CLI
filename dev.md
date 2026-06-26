# Air Development Guide

## Purpose

Air is the local CLI framework for this WSL user. Source code is under
`AIR_HOME`; generated user data is under `AIR_USER_HOME`:

```bash
AIR_HOME=/home/aircreach/.local/share/air
AIR_USER_HOME=$HOME/.air
AIR_CONFIG_HOME=$AIR_USER_HOME/config
AIR_STATE_HOME=$AIR_USER_HOME/state
AIR_CACHE_HOME=$AIR_USER_HOME/cache
AIR_RUNTIME_HOME=$AIR_USER_HOME/runtime
AIR_LOG_HOME=$AIR_USER_HOME/logs
```

Do not introduce `~/.config/air` or scattered plugin state. Code and default
contract files stay in `AIR_HOME`; user config, runtime state, cache, logs, and
managed binaries stay in the `~/.air` split above.

## Core Shape

Main entrypoints:

- `/home/aircreach/.local/bin/air`: executable CLI shim.
- `air.bash`: sources Air libraries and commands, defines `air` and `air_init`.
- `ui/`: Air native CLI UI subsystem: interaction context, component registry, layout/effects layers, flow runner, helper-mode state, helper adapter, and docs.
- `commands/*.sh`: core CLI commands such as `plugin`, `enable`, `disable`, `reset`, and `config`.
- `lib/plugin.sh`: plugin protocol, lifecycle, command dispatch, runtime dispatch.
- `plugins/<plugin>`: plugin code.
- `~/.air/config/plugins/<plugin>`: user-editable plugin settings.
- `~/.air/state/plugins/<plugin>`: runtime state and enable/setup markers.
- `~/.air/runtime/plugins/<plugin>`: generated shell runtimes and managed binaries.

Load order in `air.bash`:

1. source root UI from `ui/`
2. source compatibility output helpers from `lib/output`
3. source common libs from `lib`
4. source core commands from `commands`
5. dispatch `air <command>`
6. dispatch shell startup through `air_init bash`

`lib/` should stay product-neutral. User-facing interaction belongs in `ui/`. Plugins should call the `ui ...` Bash API rather than printing ad hoc interactive UI.

Air UI has two surfaces:

- User-facing native command: `air ui`, `air ui status`, `air ui components`, `air ui example [component] [--static|-s]`, `air ui preview`, `air ui check`, `air ui run <flow.toml>`, `air ui enable --helper`, `air ui disable --helper`.
- Internal API for core and plugins: `ui ...`. Plugins never call `air-ui` directly.

UI implementation model:

- `ui/components/<component>/` contains first-class component entrypoints and examples. Existing Bash implementations may be shimmed while the component API is being migrated.
- `ui/layout/` owns product layout primitives such as `split`, `step-rail`, `wizard`, and `viewport`; it is separate from ordinary components.
- `ui/effects/` owns explicit time-based rendering. Effects must not run during shell startup or hidden checks.
- `ui/docs/` contains UI documentation; component folders should not grow per-component README files.
- `lib/terminal.sh` contains product-neutral TTY, width, color, and ANSI primitives.
- Route status markers through `ui marker`; do not hand-write status glyphs.
- Use `[done]`, `[warn]`, and `[error]` in inline text.
- Prefer per-call component parameters such as `--bar`, `--width`, `--spinner`, and `--style` over new per-component global environment variables.
- `ui/flow.sh` runs caller-owned TOML flows as a composite UI component; Air does not discover or list flows. Flow navigation uses a stepper/timeline, not a progress bar.
- `ui spinner`/`ui task` is the default loading affordance for unknown-duration work. `ui progress` is only for measured work such as downloads, installs, builds, scans, or transfers.
- Helper UI is opt-in through `air ui enable --helper`; basic Bash UI remains the default and shell-startup-safe fallback.
- Interactive prompts write UI to stderr and return selected values on stdout.
- Commands must honor `--plain`, `--non-interactive`, `--yes`, and `NO_COLOR`.
- During active development, do not keep old component flags, aliases, or dedicated compatibility branches in code. Update docs and examples to the current API instead.

See `ui/docs/` for the full component, layout, terminal design, and plugin usage rules.

## Plugin Contract

A plugin is a directory under `plugins/<id>` with a slim root and explicit implementation/resource folders:

```text
plugin.toml
commands.toml
README.md
lifecycle.sh
runtime.sh
settings.sh
src/
  state.sh
  commands.sh
  lib/*.sh
  actions/*.sh
  <plugin-owned-domain>/
tests/
```

Required conventions:

- `plugin.toml` declares `schema`, `id`, `name`, `version`, `description`, `command`, `[entry]`, and event/action mappings.
- `commands.toml` declares public plugin commands, nested command groups, usage, summaries, aliases, and handler functions.
- If `command = "env"`, Air routes `air env ...` to function `air_env`.
- Shared plugin code lives in `src/lib/*.sh` and `src/state.sh`.
- CLI handler implementation lives in `src/commands.sh`.
- Runtime initialization lives at plugin root `runtime.sh` as `runtime_init <shell>`.
- Lifecycle and diagnostics live at plugin root `lifecycle.sh` and expose `plugin_setup`, `plugin_enable`, `plugin_disable`, `plugin_reset`, and `plugin_status`. A plugin may also expose `plugin_preflight <purpose>` for enable/check health gates.
- Discoverable plugin-owned things live under `src/<domain>/`, using plugin-specific manifests such as `capability.toml`, `renderer.toml`, or `*.theme.toml`.
- Default settings live at plugin root `settings.sh`.
- Plugin paths must use `plugin_config_dir`, `plugin_state_dir`,
  `plugin_runtime_dir`, `plugin_cache_dir`, `plugin_data_dir`, and
  `plugin_settings_path`; never write generated data into `AIR_HOME`.

Keep plugin-specific logic inside the plugin. Air core should stay generic: discovery, dispatch, lifecycle, resource discovery, state paths, and shared UI helpers only.

Use `air plugin scaffold <id>` to create a new plugin skeleton and `air plugin check <id>` to check structure health. `air enable <id>` refuses plugins with contract errors and asks before enabling warning-only plugins.

## Shell Startup Rules

`.bashrc` should only contain one Air core marker:

```bash
export AIR_HOME="${AIR_HOME:-/home/aircreach/.local/share/air}"
export AIR_USER_HOME="${AIR_USER_HOME:-$HOME/.air}"
export AIR_CONFIG_HOME="${AIR_CONFIG_HOME:-$AIR_USER_HOME/config}"
export AIR_STATE_HOME="${AIR_STATE_HOME:-$AIR_USER_HOME/state}"
export AIR_CACHE_HOME="${AIR_CACHE_HOME:-$AIR_USER_HOME/cache}"
export AIR_RUNTIME_HOME="${AIR_RUNTIME_HOME:-$AIR_USER_HOME/runtime}"
export AIR_LOG_HOME="${AIR_LOG_HOME:-$AIR_USER_HOME/logs}"
[ -r "$AIR_HOME/air.bash" ] && . "$AIR_HOME/air.bash"
command -v air_init >/dev/null 2>&1 && air_init bash
```

Startup code must be:

- idempotent
- quiet unless reporting an actionable warning
- bounded and not prone to hanging
- safe when a plugin is disabled or missing setup
- safe when a plugin is broken; `air_init` skips unusable plugins quietly and leaves details to `air plugin check <id>`

Do not add `BASH_ENV` or `.profile` integration from core. Non-interactive Bash injection belongs to the `env` plugin and must remain explicitly opt-in.

## State Rules

Use:

```text
$AIR_CONFIG_HOME/plugins/<plugin>
$AIR_STATE_HOME/plugins/<plugin>
$AIR_RUNTIME_HOME/plugins/<plugin>
$AIR_CACHE_HOME/plugins/<plugin>
```

Avoid:

- `~/.config/air`
- implicit global files
- plugin state in plugin code directories
- generated binaries in plugin source directories
- empty placeholder directories unless runtime needs them immediately

Backups should be created only when modifying an external user file such as `.bashrc`, not during ordinary `list` or `check` commands.

## Safety Rules

- New plugin behavior should default disabled.
- Lifecycle commands may prepare state; runtime startup should not install packages or perform network access.
- Destructive operations belong in explicit `reset` or user-requested cleanup paths.
- Keep shell edits minimal and marker-based.
- Prefer generated state files that are easy to inspect and recover.

## Development Checks

Run these after framework or plugin changes:

```bash
bash -n /home/aircreach/.local/share/air/air.bash \
  /home/aircreach/.local/share/air/commands/*.sh \
  /home/aircreach/.local/share/air/lib/*.sh \
  /home/aircreach/.local/share/air/lib/output/*.sh \
  /home/aircreach/.local/share/air/ui/*.sh \
  /home/aircreach/.local/share/air/ui/themes/*.sh \
  /home/aircreach/.local/share/air/plugins/*/*.sh \
  /home/aircreach/.local/share/air/plugins/*/src/*.sh \
  /home/aircreach/.local/share/air/plugins/*/src/lib/*.sh \
  /home/aircreach/.local/share/air/plugins/*/src/actions/*.sh \
  /home/aircreach/.local/share/air/plugins/*/src/*/*/*.sh

/home/aircreach/.local/bin/air plugin
/home/aircreach/.local/bin/air plugin check env
/home/aircreach/.local/bin/air plugin check theme
/home/aircreach/.local/bin/air plugin status env
/home/aircreach/.local/bin/air plugin status theme
find /home/aircreach/.local/share/air -type d -empty
```

For shell startup regressions:

```bash
timeout 10 bash -ic 'type air; air plugin; true'
```

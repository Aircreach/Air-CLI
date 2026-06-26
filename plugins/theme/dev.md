# Theme Plugin Development Guide

## Purpose

`theme` manages interactive prompt themes and renderer integrations. Starship is the current official renderer.

## Directory Model

```text
plugins/theme/
  plugin.toml
  commands.toml
  lifecycle.sh
  runtime.sh
  settings.sh
  src/
    commands.sh
    state.sh
    actions/restore-venv-prompt.sh
    lib/theme.sh
    lib/renderer.sh
    lib/prompt.sh
    renderers/starship/renderer.toml
    renderers/starship/renderer.sh
    renderers/starship/themes/*.theme.toml
    renderers/starship/themes/*.toml
```

User data is split by purpose:

```text
~/.air/config/plugins/theme/
  settings.sh

~/.air/state/plugins/theme/
  enabled
  setup
  state.sh

~/.air/runtime/plugins/theme/
  renderers/starship/bin/starship
```

## Dynamic Model

- `commands.toml` generates `air theme --help` and `air theme renderer --help`.
- `src/renderers/<id>/renderer.toml` makes a renderer discoverable.
- `src/renderers/<id>/themes/*.theme.toml` makes themes discoverable for that renderer.
- `plugin.toml` `[events]` maps lifecycle events to neutral actions in `src/actions`.
- `plugin_preflight` blocks enable when the selected renderer cannot be used or installed.
- Runtime must degrade quietly: missing renderer binaries should not print shell errors or replace the current prompt.

## Checks

```bash
bash -n plugins/theme/*.sh plugins/theme/src/*.sh plugins/theme/src/lib/*.sh plugins/theme/src/actions/*.sh plugins/theme/src/renderers/*/*.sh
air plugin check theme
air theme --help
air theme list
air theme renderer --help
air theme renderer list
air theme renderer status
air theme current
```

# Air

Air is a local CLI framework for this WSL user. Source code lives in one
framework home, while user-owned config/state/runtime data lives under
`~/.air`:

```bash
AIR_HOME=/home/aircreach/.local/share/air
AIR_USER_HOME=$HOME/.air
AIR_CONFIG_HOME=$AIR_USER_HOME/config
AIR_STATE_HOME=$AIR_USER_HOME/state
AIR_CACHE_HOME=$AIR_USER_HOME/cache
AIR_RUNTIME_HOME=$AIR_USER_HOME/runtime
AIR_LOG_HOME=$AIR_USER_HOME/logs
```

## Layout

- `air.bash`: bootstrap and command dispatcher
- `commands/`: core commands such as `plugin`, `enable`, `disable`, `reset`,
  and `config`
- `lib/`: shared shell libraries
- `ui/`: native UI subsystem, components, layouts, effects, and docs
- `plugins/`: plugin implementations such as `env` and `theme`

Runtime data is generated outside the repo:

- `~/.air/config`: user-editable settings and activation choices
- `~/.air/state`: runtime state and enable/setup markers
- `~/.air/runtime`: generated shell runtimes and managed binaries
- `~/.air/cache`: downloads, backups, and rebuildable cache files
- `~/.air/logs`: logs

## Start

```bash
source ./air.bash
air --help
air ui
air plugin
```

If installed, the CLI entrypoint also lives at `/home/aircreach/.local/bin/air`.

## Development Notes

- Keep product-neutral code in `lib/`
- Keep user-facing interaction in `ui/`
- Keep plugin-specific logic inside `plugins/<plugin>`
- Keep generated data out of the source tree; use the `air_*_home` and
  `plugin_*_dir` helpers

See `dev.md` and `ui/docs/` for deeper guidance.

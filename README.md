# Air

Air is a local CLI framework for this WSL user. It keeps shell tooling,
plugin lifecycle, and the native terminal UI under one home:

```bash
AIR_HOME=/home/aircreach/.local/share/air
AIR_STATE_HOME=$AIR_HOME/state
```

## Layout

- `air.bash`: bootstrap and command dispatcher
- `commands/`: core commands such as `plugin`, `enable`, `disable`, `reset`,
  and `config`
- `lib/`: shared shell libraries
- `ui/`: native UI subsystem, components, layouts, effects, and docs
- `plugins/`: plugin implementations such as `env` and `theme`
- `state/`: local plugin and UI state

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
- Keep state under `state/`

See `dev.md` and `ui/docs/` for deeper guidance.

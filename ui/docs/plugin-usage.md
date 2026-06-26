# Plugin Usage

Plugins should call the `ui ...` Bash API and never invoke `air-ui` directly.

Recommended plugin patterns:

- Use `ui check-item` for feasibility/preflight/status output.
- Use `ui table`, `ui kv`, and `ui summary` for data.
- Use `ui input`, `ui select`, and `ui confirm` for configuration flows.
- Use `ui flow <flow.toml>` only when a command needs a guided sequence.
- Use `ui spinner` or `ui task` for unknown-duration work.
- Use `ui progress` only when total work is known.

Plugin commands must honor `--plain`, `--non-interactive`, `--yes`, and
`NO_COLOR` through the shared Air context.

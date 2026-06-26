# Env

Air plugin for explicit Bash environment capabilities such as `local-bin`, `pyenv`, and `nvm`.

Framework contract files live at the plugin root. Env implementation lives in
`src/`, built-in capability packages live in `src/capabilities/`, default
configuration lives in root `settings.sh`, user choices live under
`$AIR_CONFIG_HOME/plugins/env`, runtime markers live under
`$AIR_STATE_HOME/plugins/env`, and generated Bash runtimes live under
`$AIR_RUNTIME_HOME/plugins/env`.

Each capability declares target-specific loaders. `bashrc` is the interactive target; `bash-env` is the lightweight non-interactive target and only uses static PATH/export logic.

Capabilities may declare inputs in `capability.toml`. Activate or configure them with flags, for example:

```bash
air env activate nvm bash-env --nvm-dir '$HOME/.nvm' --node-version default
air env configure pyenv --pyenv-root '$HOME/.pyenv'
```

`bash-env` runtime is generated from logical parameters and avoids machine-specific Node bin paths.

`air enable env` installs and activates detected built-ins for `local-bin`,
`pyenv`, and `nvm`, enables `bash-env` injection, refreshes generated runtimes,
and loads the interactive runtime into the current shell.

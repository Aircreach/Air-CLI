# Env Plugin Development Guide

## Purpose

`env` manages explicit Bash environment capabilities such as `local-bin`, `nvm`, and `pyenv`.

## Directory Model

```text
plugins/env/
  plugin.toml
  commands.toml
  lifecycle.sh
  runtime.sh
  settings.sh
  src/
    commands.sh
    state.sh
    capabilities/<name>/capability.toml
    capabilities/<name>/targets/bashrc.bash
    capabilities/<name>/targets/bash-env.bash
```

User state stays under:

```text
state/plugins/env/
  enabled
  setup
  settings.sh
  capabilities/<name>/resource.toml
  capabilities/<name>/targets/<target>.bash
  targets/bashrc.list
  targets/bash-env.list
  inject/bash-env.enabled
  runtime/bashrc.bash
  runtime/bash_env.bash
```

Built-in capability packages live in `src/capabilities`. Installed capabilities are copied into state; runtime loads only the state copy.

Capability manifests declare target-specific loaders:

```toml
[targets.bashrc]
loader = "targets/bashrc.bash"
mode = "lazy"

[targets.bash-env]
loader = "targets/bash-env.bash"
mode = "static"
```

Capability manifests can also declare inputs used by `air env activate` and `air env configure`:

```toml
[inputs.nvm_dir]
type = "path"
env = "NVM_DIR"
default = "$HOME/.nvm"
prompt = "nvm directory"
required = true
targets = ["bashrc", "bash-env"]
validate = "dir"
```

Configured values are saved in `state/plugins/env/capabilities/<name>/params.sh`. Runtime generation uses those logical values and keeps `$HOME` relative paths portable.

## Runtime

`runtime.sh` exposes `runtime_init bash`, which sources the generated `bashrc` runtime and exports `BASH_ENV` when bash-env injection is enabled.

`bash-env` uses generated static runtime at `state/plugins/env/runtime/bash_env.bash`; it must not source `nvm.sh`, run `nvm use`, run `pyenv init`, load shell completion, or execute arbitrary user scripts during non-interactive startup.

`bashrc` uses generated interactive runtime at `state/plugins/env/runtime/bashrc.bash`; built-in `nvm` and `pyenv` use fast PATH injection plus lazy shell functions for full initialization.

## Commands

Public command metadata lives in `commands.toml`. Handlers live in `src/commands.sh`.

```bash
air env list
air env add <local-bin|nvm|pyenv>
air env register <name> <script>
air env unregister <name>
air env validate <name> [bashrc|bash-env]
air env activate <name> <bashrc|bash-env> [--set key=value] [dynamic flags]
air env configure <name> [--target bashrc|bash-env] [--set key=value] [dynamic flags]
air env deactivate <name> <bashrc|bash-env>
air env refresh
air env inject <enable|disable|status> bash-env
air env analysis [--probe]
```

## Checks

```bash
bash -n plugins/env/*.sh plugins/env/src/*.sh plugins/env/src/capabilities/*/targets/*.bash
air plugin check env
air env --help
air env list
air env activate nvm bash-env --nvm-dir '$HOME/.nvm' --node-version default --yes
air env analysis
```

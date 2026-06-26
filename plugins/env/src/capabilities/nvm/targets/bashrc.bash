export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [ -n "${NVM_BIN:-}" ] && [ -d "$NVM_BIN" ]; then
    case ":${PATH:-}:" in
        *":$NVM_BIN:"*) ;;
        *) PATH="$NVM_BIN${PATH:+:$PATH}" ;;
    esac
elif [ -r "$NVM_DIR/alias/default" ]; then
    IFS= read -r _air_env_nvm_default < "$NVM_DIR/alias/default" || true
    case "$_air_env_nvm_default" in
        ''|N/A|system|default) ;;
        *)
            _air_env_nvm_bin="$NVM_DIR/versions/node/$_air_env_nvm_default/bin"
            if [ -d "$_air_env_nvm_bin" ]; then
                export NVM_BIN="$_air_env_nvm_bin"
                case ":${PATH:-}:" in
                    *":$NVM_BIN:"*) ;;
                    *) PATH="$NVM_BIN${PATH:+:$PATH}" ;;
                esac
            fi
            ;;
    esac
    unset _air_env_nvm_default _air_env_nvm_bin
fi
export PATH

_air_env_nvm_load() {
    unset -f nvm node npm npx 2>/dev/null || true
    [ -s "$NVM_DIR/nvm.sh" ] || return 127
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    command -v nvm >/dev/null 2>&1 && nvm use --silent default >/dev/null 2>&1 || true
}

nvm() {
    _air_env_nvm_load || return "$?"
    nvm "$@"
}

if ! command -v node >/dev/null 2>&1; then
    node() {
        _air_env_nvm_load || return "$?"
        node "$@"
    }
fi

if ! command -v npm >/dev/null 2>&1; then
    npm() {
        _air_env_nvm_load || return "$?"
        npm "$@"
    }
fi

if ! command -v npx >/dev/null 2>&1; then
    npx() {
        _air_env_nvm_load || return "$?"
        npx "$@"
    }
fi

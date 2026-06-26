export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

if [ -d "$PYENV_ROOT/shims" ]; then
    case ":${PATH:-}:" in
        *":$PYENV_ROOT/shims:"*) ;;
        *) PATH="$PYENV_ROOT/shims${PATH:+:$PATH}" ;;
    esac
fi

if [ -d "$PYENV_ROOT/bin" ]; then
    case ":${PATH:-}:" in
        *":$PYENV_ROOT/bin:"*) ;;
        *) PATH="$PYENV_ROOT/bin${PATH:+:$PATH}" ;;
    esac
fi
export PYENV_ROOT PATH

_air_env_pyenv_load() {
    unset -f pyenv 2>/dev/null || true
    command -v pyenv >/dev/null 2>&1 || return 127
    eval "$(command pyenv init --path)"
    eval "$(command pyenv init -)"
}

pyenv() {
    _air_env_pyenv_load || return "$?"
    pyenv "$@"
}

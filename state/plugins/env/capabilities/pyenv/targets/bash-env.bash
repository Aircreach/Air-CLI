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

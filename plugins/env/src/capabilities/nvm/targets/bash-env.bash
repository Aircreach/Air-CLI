export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [ -n "${NVM_BIN:-}" ] && [ -d "$NVM_BIN" ]; then
    case ":${PATH:-}:" in
        *":$NVM_BIN:"*) ;;
        *) PATH="$NVM_BIN${PATH:+:$PATH}" ;;
    esac
fi
export PATH

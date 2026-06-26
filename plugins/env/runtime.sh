# Env runtime initialization.

runtime_init() {
    local shell="${1:-bash}"

    case "$shell" in
        bash) ;;
        *) return 0 ;;
    esac

    env_runtime_load_target bashrc || true
    env_runtime_export_bash_env || true
}

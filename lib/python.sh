# Python helpers.

is_project() {
    local path="${1:-$PWD}"

    has_any_up "$path" \
        pyproject.toml \
        requirements.txt \
        setup.py \
        setup.cfg \
        Pipfile \
        poetry.lock \
        .python-version
}

python_version_file() {
    first_up "${1:-$PWD}" .python-version
}

python_version_from_venv() {
    local config="$1/pyvenv.cfg"
    local line value

    [ -r "$config" ] || return 1
    while IFS= read -r line; do
        case "$line" in
            version\ =*)
                value="${line#version =}"
                value="${value#"${value%%[![:space:]]*}"}"
                [ -n "$value" ] || return 1
                printf 'v%s\n' "$value"
                return 0
                ;;
        esac
    done < "$config"

    return 1
}

version() {
    local output

    if command -v python >/dev/null 2>&1; then
        output="$(python --version 2>/dev/null)" || output=""
        if [ -n "$output" ]; then
            printf 'v%s\n' "${output#Python }"
            return 0
        fi
    fi

    if command -v python3 >/dev/null 2>&1; then
        output="$(python3 --version 2>/dev/null)" || output=""
        if [ -n "$output" ]; then
            printf 'v%s\n' "${output#Python }"
            return 0
        fi
    fi

    return 1
}

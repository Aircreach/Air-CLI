# Filesystem helpers.

find_up() {
    local start="${1:-$PWD}"
    local dir name

    shift || true
    [ "$#" -gt 0 ] || return 1

    if [ -d "$start" ]; then
        dir="$start"
    else
        dir="${start%/*}"
        [ "$dir" != "$start" ] || dir="."
    fi

    while [ "$dir" != "/" ]; do
        for name in "$@"; do
            if [ -e "$dir/$name" ]; then
                printf '%s\n' "$dir/$name"
                return 0
            fi
        done

        dir="${dir%/*}"
        [ -n "$dir" ] || dir="/"
    done

    return 1
}

has_up() {
    find_up "$@" >/dev/null
}

has_any_up() {
    local start="${1:-$PWD}"
    local dir name

    shift || true
    [ "$#" -gt 0 ] || return 1

    if [ -d "$start" ]; then
        dir="$start"
    else
        dir="${start%/*}"
        [ "$dir" != "$start" ] || dir="."
    fi

    while :; do
        for name in "$@"; do
            [ -e "$dir/$name" ] && return 0
        done

        [ "$dir" = "/" ] && return 1
        dir="${dir%/*}"
        [ -n "$dir" ] || dir="/"
    done
}

first_up() {
    local start="${1:-$PWD}"
    local dir name

    shift || true
    [ "$#" -gt 0 ] || return 1

    if [ -d "$start" ]; then
        dir="$start"
    else
        dir="${start%/*}"
        [ "$dir" != "$start" ] || dir="."
    fi

    while :; do
        for name in "$@"; do
            if [ -e "$dir/$name" ]; then
                printf '%s\n' "$dir/$name"
                return 0
            fi
        done

        [ "$dir" = "/" ] && return 1
        dir="${dir%/*}"
        [ -n "$dir" ] || dir="/"
    done
}

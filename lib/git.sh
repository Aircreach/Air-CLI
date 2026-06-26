# Git helpers.

git_dir() {
    local path="${1:-$PWD}"
    local marker line dir

    marker="$(first_up "$path" .git)" || return 1
    if [ -d "$marker" ]; then
        printf '%s\n' "$marker"
        return 0
    fi

    if [ -f "$marker" ]; then
        IFS= read -r line < "$marker" || return 1
        case "$line" in
            'gitdir: '*)
                dir="${line#gitdir: }"
                case "$dir" in
                    /*) printf '%s\n' "$dir" ;;
                    *) printf '%s\n' "${marker%/.git}/$dir" ;;
                esac
                return 0
                ;;
        esac
    fi

    return 1
}

is_repo() {
    git_dir "${1:-$PWD}" >/dev/null
}

root() {
    local path="${1:-$PWD}"
    local marker

    marker="$(first_up "$path" .git)" || return 1
    printf '%s\n' "${marker%/.git}"
}

branch() {
    local path="${1:-$PWD}"
    local dir head branch_name

    dir="$(git_dir "$path")" || return 1
    if [ -r "$dir/HEAD" ]; then
        IFS= read -r head < "$dir/HEAD" || head=""
        case "$head" in
            'ref: refs/heads/'*)
                printf '%s\n' "${head#ref: refs/heads/}"
                return 0
                ;;
            'ref: '*)
                printf '%s\n' "${head##*/}"
                return 0
                ;;
        esac
    fi

    command -v git >/dev/null 2>&1 || return 1
    branch_name="$(git -C "$path" symbolic-ref --short -q HEAD 2>/dev/null)" || return 1
    [ -n "$branch_name" ] || return 1
    printf '%s\n' "$branch_name"
}

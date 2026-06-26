# Actions for the built-in helper UI enable flow.

helper_flow_selected_method() {
    printf '%s\n' "${AIR_UI_FLOW_RESULT_build_method:-}"
}

helper_flow_runtime_dir() {
    printf '%s\n' "$(ui_runtime_home)"
}

helper_flow_local_go_root() {
    printf '%s\n' "$(helper_flow_runtime_dir)/go"
}

helper_flow_local_go_bin() {
    printf '%s\n' "$(helper_flow_local_go_root)/bin/go"
}

helper_flow_go_version() {
    printf '%s\n' "${AIR_UI_GO_VERSION:-1.22.12}"
}

helper_flow_check_context() {
    if ui_is_plain; then
        ui check-item blocked "plain mode" "Helper UI cannot be enabled while --plain or NO_COLOR is active."
        ui check-item hint "next" "Run this command in a normal interactive terminal."
        return 1
    fi
    if ! ui_is_interactive; then
        ui check-item blocked "interactive terminal" "Helper UI enable flow requires an interactive terminal."
        ui check-item hint "next" "Open a TTY and rerun air ui enable --helper."
        return 1
    fi
    ui check-item ok "terminal" "Interactive terminal detected."
    ui check-item hint "startup safety" "No shell startup code will run helper, Docker, downloads, or installs."
    return 0
}

helper_flow_has_system_go() {
    command -v go >/dev/null 2>&1
}

helper_flow_has_docker() {
    command -v docker >/dev/null 2>&1
}

helper_flow_has_apt_sudo() {
    command -v apt >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1
}

helper_flow_can_air_local_go() {
    case "$(uname -s 2>/dev/null):$(uname -m 2>/dev/null)" in
        Linux:x86_64|Linux:amd64)
            command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

helper_flow_check_helper_or_build() {
    if ui_helper_installed; then
        ui check-item ok "helper" "$(ui_helper_path)"
        return 0
    fi

    ui check-item warning "helper" "air-ui helper is missing."
    if helper_flow_has_system_go || helper_flow_has_docker || helper_flow_can_air_local_go || helper_flow_has_apt_sudo; then
        ui check-item ok "build paths" "At least one preparation path is available."
        return 0
    fi

    ui check-item blocked "build paths" "No Go, Docker, apt/sudo, or supported local Go download path is available."
    ui check-item hint "next step" "Install Go manually or provide an executable helper at \`$(ui_helper_path)\`, then rerun this command."
    return 1
}

helper_flow_build_options() {
    if ui_helper_installed; then
        printf 'existing-helper\tUse existing helper\tAlready available at %s.\n' "$(ui_helper_path)"
        printf 'exit\tExit\tLeave helper UI disabled.\n'
        return 0
    fi
    helper_flow_has_system_go && printf 'existing-go\tExisting Go\tBuild with go already on PATH; fastest local path.\n'
    helper_flow_has_docker && printf 'docker-go\tDocker container\tBuild in a temporary golang container; no host Go install.\n'
    helper_flow_can_air_local_go && printf 'air-local-go\tAir local Go\tDownload Go into Air state only; no system changes.\n'
    helper_flow_has_apt_sudo && printf 'system-go\tSystem apt\tInstall golang-go with sudo apt; system-wide change.\n'
    printf 'exit\tExit\tLeave helper UI disabled.\n'
}

helper_flow_show_build_plan() {
    local method

    method="$(helper_flow_selected_method)"
    case "$method" in
        existing-helper)
            ui panel --title "Use existing helper" --severity ok \
                "Air found an executable helper.

Reads:
  $(ui_helper_path)

Writes:
  No helper binary changes. Final commit may write:
  $(ui_settings_path)"
            ;;
        existing-go)
            ui panel --title "Build with existing Go" --severity ok \
                "Air will run the existing Go toolchain on this machine.

Command:
  bash \"$(ui_path build-helper.sh)\"

Writes:
  $(ui_helper_path)

Later commit writes:
  $(ui_settings_path)"
            ;;
        docker-go)
            ui panel --title "Build with Docker" --severity warning \
                "Air will run a temporary Go container and mount the Air directory.

Image:
  golang:1.22

Writes:
  $(ui_helper_path)

Later commit writes:
  $(ui_settings_path)"
            ;;
        air-local-go)
            ui panel --title "Install Go into Air state" --severity warning \
                "Air will download the official Linux amd64 Go tarball into Air state, then build the helper with that local runtime.

Writes:
  $(helper_flow_local_go_root)
  $(ui_helper_path)

Later commit writes:
  $(ui_settings_path)"
            ;;
        system-go)
            ui panel --title "Install Go with apt" --severity warning \
                "Air will use sudo apt to install golang-go globally, then build the helper.

Commands:
  sudo apt update
  sudo apt install -y golang-go

Later commit writes:
  $(ui_settings_path)"
            ;;
        exit|'')
            ui check-item hint "exit" "Helper UI will not be enabled."
            return 2
            ;;
        *)
            ui check-item error "build path" "Unknown build path: $method"
            return 1
            ;;
    esac
}

helper_flow_build_existing_go() {
    ui_helper_build
}

helper_flow_build_docker_go() {
    local image="${AIR_UI_GO_DOCKER_IMAGE:-golang:1.22}"

    mkdir -p "$(dirname "$(ui_helper_path)")"
    docker run --rm \
        -v "$(ui_air_home):$(ui_air_home)" \
        -w "$(ui_path helper)" \
        "$image" \
        sh -lc "PATH=/usr/local/go/bin:\$PATH go build -o \"$(ui_helper_path)\" ."
}

helper_flow_download() {
    local url="$1" target="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$target"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$target" "$url"
    else
        return 1
    fi
}

helper_flow_build_air_local_go() {
    local version tarball url runtime go_bin

    version="$(helper_flow_go_version)"
    runtime="$(helper_flow_runtime_dir)"
    tarball="$runtime/go${version}.linux-amd64.tar.gz"
    url="https://go.dev/dl/go${version}.linux-amd64.tar.gz"
    go_bin="$(helper_flow_local_go_bin)"

    mkdir -p "$runtime"
    if [ ! -x "$go_bin" ]; then
        helper_flow_download "$url" "$tarball" || return 1
        rm -rf "$(helper_flow_local_go_root)"
        tar -C "$runtime" -xzf "$tarball" || return 1
    fi

    PATH="$(helper_flow_local_go_root)/bin:$PATH" ui_helper_build
}

helper_flow_build_system_go() {
    sudo apt update || return 1
    sudo apt install -y golang-go || return 1
    ui_helper_build
}

helper_flow_prepare_helper() {
    local method

    method="$(helper_flow_selected_method)"
    case "$method" in
        existing-helper)
            return 0
            ;;
        existing-go)
            helper_flow_build_existing_go
            ;;
        docker-go)
            helper_flow_build_docker_go
            ;;
        air-local-go)
            helper_flow_build_air_local_go
            ;;
        system-go)
            helper_flow_build_system_go
            ;;
        exit|'')
            ui check-item blocked "helper UI" "User chose to exit without enabling helper UI."
            return 1
            ;;
        *)
            ui check-item error "build path" "Unknown build path: $method"
            return 1
            ;;
    esac
}

helper_flow_check_usable() {
    AIR_UI_MODE=helper
    export AIR_UI_MODE
    ui_helper_available
}

helper_flow_preview() {
    air_ui_preview
}

helper_flow_commit() {
    ui_enable_helper_state
    AIR_UI_MODE=helper
    export AIR_UI_MODE
    ui check-item ok "helper UI" "Enabled. Startup remains basic/fallback-safe."
}

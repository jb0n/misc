#!/usr/bin/env bash

# generic linux setup: passwordless sudo for the invoking account, base +
# dev packages via whatever package manager the distro ships, fonts (fira
# code + hasklig) straight from github so no distro packages are needed,
# signal-desktop when the distro can do it, the nvim setup from ../nvim,
# then the third-party agents (omp + kilocode) with any api keys passed
# through (see setup_linux_3rd_party/setup.sh).
#
# the package list below is scraped from the machine this repo was born on
# (ubuntu 26.04): build-essential, golang, nodejs/npm, python3/pip, gdb,
# jq, htop, tmux, strace, tcpdump, net-tools, nmap, iperf3, traceroute,
# openssl/libssl-dev, ripgrep, fd, fzf, shellcheck -- plus a few staples
# a dev is going to reach for. names are mapped per distro; if your distro
# renames something, add it to the right case below.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            echo "usage: setup.sh [--deepseek-apikey=KEY]"
            echo
            echo "steps: passwordless sudo, base packages, fonts (hasklig),"
            echo "       nvim setup, then third-party agents with api keys."
            exit 0
            ;;
    esac
done

#---------------------------------------------------------------------
# passwordless sudo for whoever runs this script
#---------------------------------------------------------------------
grant_passwordless_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "running as root: already privileged, skipping passwordless sudo"
        return
    fi

    local whoami sudoers
    whoami="$(id -un)"
    sudoers="/etc/sudoers.d/90-$whoami"

    if [ -f "$sudoers" ] && sudo -n true >/dev/null 2>&1; then
        echo "passwordless sudo already in place for $whoami"
        return
    fi

    echo "granting passwordless sudo to $whoami (one sudo password prompt follows)..."
    sudo -v
    [ -e "$sudoers" ] && sudo cp "$sudoers" "$sudoers.bak.$(date +%Y%m%d%H%M%S)"
    echo "$whoami ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers" >/dev/null
    sudo chmod 440 "$sudoers"
    sudo visudo -c -f "$sudoers"
    echo "passwordless sudo granted ($sudoers)"
}

#---------------------------------------------------------------------
# distro-agnostic-ish package install. if the pm is unknown we skip and
# rely on the fonts step, which is fully distro-agnostic. a failed bulk
# install falls back to one package at a time so a single bad name can't
# sink the rest.
#---------------------------------------------------------------------
detect_pm() {
    if command -v apt-get >/dev/null 2>&1; then echo apt
    elif command -v dnf >/dev/null 2>&1; then echo dnf
    elif command -v pacman >/dev/null 2>&1; then echo pacman
    elif command -v zypper >/dev/null 2>&1; then echo zypper
    elif command -v apk >/dev/null 2>&1; then echo apk
    else echo unknown; fi
}

pkg_install() {
    local pm="$1"; shift
    case "$pm" in
        apt)    sudo apt-get install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm --needed "$@" ;;
        zypper) sudo zypper --non-interactive install "$@" ;;
        apk)    sudo apk add --no-cache "$@" ;;
    esac
}

install_packages() {
    local pm pkgs
    pm="$(detect_pm)"
    echo "package manager: $pm"

    case "$pm" in
        apt|dnf|pacman|zypper|apk) ;;
        *)
            echo "unknown package manager: skipping package installs (fonts are still distro-agnostic)"
            return 1
            ;;
    esac

    case "$pm" in
        apt)
            pkgs="git curl wget unzip zip fontconfig gnupg vim neovim \
                  build-essential gdb golang python3 python3-pip nodejs npm libssl-dev \
                  jq htop tmux strace tcpdump net-tools nmap iperf3 traceroute \
                  ripgrep fd-find fzf shellcheck"
            sudo apt-get update
            ;;
        dnf)
            pkgs="git curl wget unzip zip fontconfig vim neovim \
                  gcc gcc-c++ make gdb golang python3 python3-pip nodejs npm openssl-devel \
                  jq htop tmux strace tcpdump net-tools nmap iperf3 traceroute \
                  ripgrep fd-find fzf ShellCheck"
            ;;
        pacman)
            pkgs="git curl wget unzip zip fontconfig vim neovim \
                  base-devel gdb go python python-pip nodejs npm openssl \
                  jq htop tmux strace tcpdump net-tools nmap iperf3 traceroute \
                  ripgrep fd fzf shellcheck"
            sudo pacman -Sy --noconfirm
            ;;
        zypper)
            pkgs="git curl wget unzip zip fontconfig vim neovim \
                  gcc gcc-c++ make gdb golang python3 python3-pip nodejs npm openssl-devel \
                  jq htop tmux strace tcpdump net-tools nmap iperf3 traceroute \
                  ripgrep fd fzf ShellCheck"
            ;;
        apk)
            # libstdc++/libgcc because the omp musl binary links them dynamically
            pkgs="git curl wget unzip zip fontconfig vim neovim \
                  build-base gdb go python3 py3-pip nodejs npm openssl-dev \
                  jq htop tmux strace tcpdump net-tools nmap iperf3 traceroute \
                  ripgrep fd fzf shellcheck libstdc++ libgcc"
            ;;
    esac

    read -r -a pkgs_arr <<< "$pkgs"
    if pkg_install "$pm" "${pkgs_arr[@]}"; then
        return
    fi
    echo "bulk install failed; retrying one package at a time so a bad name can't sink the rest"
    for p in "${pkgs_arr[@]}"; do
        pkg_install "$pm" "$p" || echo "  could not install $p (skipping)"
    done
}

#---------------------------------------------------------------------
# fonts: fira code + hasklig, downloaded straight from github into
# ~/.fonts -- same approach as vim/setup.sh, no distro packages.
#---------------------------------------------------------------------
FIRA_URL=https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip
HASKLIG_URL=https://github.com/i-tu/Hasklig/releases/download/v1.2/Hasklig-1.2.zip

install_font() {
    local url="$1" fname dir
    fname="$(basename "$url")"
    dir="$HOME/.fonts"
    mkdir -p "$dir"
    if [ -e "$dir/$fname" ]; then
        echo "font $fname already installed"
        return
    fi
    echo "downloading $fname"
    wget -q -O "$dir/$fname" "$url"
    (cd "$dir" && unzip -oq "$fname")
    fc-cache -f >/dev/null
}

install_fonts() {
    if ! command -v wget >/dev/null 2>&1; then
        echo "wget not available: skipping fonts"
        return
    fi
    install_font "$FIRA_URL"
    install_font "$HASKLIG_URL"
    echo "fonts installed into ~/.fonts (hasklig + fira code)"
}

#---------------------------------------------------------------------
# signal-desktop: needed for sure, but the install path is distro-
# specific. apt gets the official signal repo (same one this repo was
# scraped from); everything else falls back to flatpak if present,
# otherwise warns and skips.
#---------------------------------------------------------------------
install_signal_desktop() {
    if command -v signal-desktop >/dev/null 2>&1; then
        echo "signal-desktop already installed"
        return
    fi

    case "$(detect_pm)" in
        apt)
            local keyring=/usr/share/keyrings/signal-desktop-keyring.gpg
            local sources=/etc/apt/sources.list.d/signal-desktop.sources
            echo "installing signal-desktop from the official apt repo..."
            wget -qO- https://updates.signal.org/desktop/apt/keys.asc \
                | sudo gpg --dearmor --yes -o "$keyring"
            sudo tee "$sources" >/dev/null <<EOF
Types: deb
URIs: https://updates.signal.org/desktop/apt
Suites: xenial
Components: main
Architectures: amd64
Signed-By: $keyring
EOF
            sudo apt-get update
            sudo apt-get install -y signal-desktop
            ;;
        *)
            if command -v flatpak >/dev/null 2>&1; then
                echo "installing signal-desktop via flatpak..."
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                flatpak install -y flathub org.signal.Signal \
                    || echo "signal-desktop: flatpak install failed, install it manually"
            else
                echo "signal-desktop: no apt repo and no flatpak on this distro; install it manually"
            fi
            ;;
    esac
}

#---------------------------------------------------------------------
# the nvim setup from the repo root (run from the nvim dir so its
# relative "files/" paths resolve)
#---------------------------------------------------------------------
run_nvim_setup() {
    echo "running nvim/setup.sh"
    (cd "$REPO/nvim" && bash setup.sh) \
        || echo "warning: nvim setup did not finish cleanly (continuing anyway)"
}

#---------------------------------------------------------------------
grant_passwordless_sudo
install_packages || true
install_fonts
install_signal_desktop
run_nvim_setup

echo "==> third-party setup (omp + kilocode + api keys)"
bash "$REPO/setup_linux_3rd_party/setup.sh" "$@"

echo "ok, all set"

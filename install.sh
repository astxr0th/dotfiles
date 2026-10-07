#!/usr/bin/env bash
#
#  dotfiles installer — Arch Linux and Arch-based distros
#  (Arch, Artix, EndeavourOS, CachyOS, Manjaro, Garuda, ...)
#
#  usage: ./install.sh [options]
#
#    -y, --yes          don't ask, answer yes to everything
#    -c, --copy         copy files instead of symlinking them
#    -n, --no-packages  only link the configs, skip package installs
#    -e, --extras       also install the extra apps (browser, discord, ...)
#    -h, --help         show this help
#

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

ASSUME_YES=0
COPY=0
PACKAGES=1
EXTRAS=0

# --------------------------------------------------------------------------
#  packages
# --------------------------------------------------------------------------

# window manager, shell and desktop plumbing
PKGS_CORE=(
    mangowm-git quickshell qt6-5compat
    xdg-desktop-portal-wlr polkit-gnome
    pipewire pipewire-pulse wireplumber
    networkmanager bluez-utils brightnessctl lm_sensors
    libnotify xdg-utils
)

# terminal and cli tools
PKGS_CLI=(
    kitty foot zsh spaceship-prompt starship
    neovim yazi fastfetch btop mpv git
)

# theming
PKGS_THEME=(
    python-pywal16-git wallust awww imagemagick
    ttf-iosevka ttf-iosevka-nerd ttf-jetbrains-mono-nerd
    papirus-icon-theme
)

# screenshots, recording, clipboard
PKGS_MEDIA=(
    grim slurp wl-clipboard cliphist gpu-screen-recorder
)

# older setup, still configured (launcher, bar, notifications)
PKGS_LEGACY=(
    rofi waybar swaync
)

# apps the mango config launches, not needed for the rice itself
PKGS_EXTRAS=(
    zen-browser-bin equibop-bin steam
)

# configs that get linked into ~/.config
CONFIGS=(
    mango quickshell kitty foot nvim yazi fastfetch btop mpv
    rofi waybar swaync wal wallust environment.d bin starship.toml
)

# --------------------------------------------------------------------------
#  helpers
# --------------------------------------------------------------------------

if [[ -t 1 ]]; then
    B=$'\e[1m' R=$'\e[0m' RED=$'\e[31m' GRN=$'\e[32m' YLW=$'\e[33m' MAG=$'\e[35m' CYN=$'\e[36m'
else
    B='' R='' RED='' GRN='' YLW='' MAG='' CYN=''
fi

info() { printf '%s::%s %s\n' "$CYN$B" "$R" "$*"; }
ok()   { printf '%s ✓%s %s\n' "$GRN$B" "$R" "$*"; }
warn() { printf '%s !%s %s\n' "$YLW$B" "$R" "$*"; }
die()  { printf '%s ✗%s %s\n' "$RED$B" "$R" "$*" >&2; exit 1; }
step() { printf '\n%s==>%s %s%s%s\n' "$MAG$B" "$R" "$B" "$*" "$R"; }

ask() {
    ((ASSUME_YES)) && return 0
    local reply
    read -rp "$(printf '%s ?%s %s [Y/n] ' "$MAG$B" "$R" "$1")" reply
    [[ -z $reply || $reply =~ ^[Yy] ]]
}

usage() {
    sed -n '3,14p' "${BASH_SOURCE[0]}" | sed 's/^#\s\{0,1\}//'
    exit 0
}

banner() {
    printf '%s' "$MAG$B"
    cat <<'EOF'

       █▀▄ █▀█ ▀█▀ █▀▀ █ █   █▀▀ █▀
       █▄▀ █▄█  █  █▀  █ █▄▄ ██▄ ▄█

        mango · quickshell · kitty
EOF
    printf '%s\n' "$R"
}

# --------------------------------------------------------------------------
#  steps
# --------------------------------------------------------------------------

check_system() {
    step "checking system"
    ((EUID != 0)) || die "don't run this as root, it will ask for your password when needed"
    command -v pacman >/dev/null || die "pacman not found, this script is for Arch-based distros"

    if command -v sudo >/dev/null; then
        SUDO=sudo
    elif command -v doas >/dev/null; then
        SUDO=doas
    else
        die "need sudo or doas to install packages"
    fi

    local distro
    distro=$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-$NAME}") || distro="unknown"
    ok "$distro, using $SUDO"
}

install_aur_helper() {
    if command -v paru >/dev/null; then
        AUR=paru
    elif command -v yay >/dev/null; then
        AUR=yay
    else
        step "installing an AUR helper"
        ask "no AUR helper found, install paru?" || die "an AUR helper is needed for mango and a few other packages"
        $SUDO pacman -S --needed --noconfirm base-devel git
        local tmp
        tmp=$(mktemp -d)
        git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
        (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
        AUR=paru
    fi
    ok "AUR helper: $AUR"
}

install_packages() {
    step "installing packages"
    local pkgs=("${PKGS_CORE[@]}" "${PKGS_CLI[@]}" "${PKGS_THEME[@]}" "${PKGS_MEDIA[@]}" "${PKGS_LEGACY[@]}")
    if ((EXTRAS)) || { ((!ASSUME_YES)) && ask "also install the extra apps (${PKGS_EXTRAS[*]})?"; }; then
        pkgs+=("${PKGS_EXTRAS[@]}")
    fi

    info "${#pkgs[@]} packages: ${pkgs[*]}"
    $SUDO pacman -Sy --needed --noconfirm archlinux-keyring 2>/dev/null || true
    "$AUR" -S --needed "${pkgs[@]}"
    ok "packages installed"
}

link() {
    local src=$1 dst=$2

    # already pointing at the repo, nothing to do
    if [[ -L $dst && $(readlink -f "$dst") == "$(readlink -f "$src")" ]]; then
        ok "${dst/#$HOME/\~} (already linked)"
        return
    fi

    if [[ -e $dst || -L $dst ]]; then
        mkdir -p "$BACKUP"
        mv "$dst" "$BACKUP/"
        warn "backed up ${dst/#$HOME/\~}"
    fi

    mkdir -p "$(dirname "$dst")"
    if ((COPY)); then
        cp -a "$src" "$dst"
    else
        ln -s "$src" "$dst"
    fi
    ok "${dst/#$HOME/\~}"
}

fix_paths() {
    # a few configs need absolute paths, swap the original home dir for yours
    if [[ $HOME == /home/wxw ]]; then return; fi
    step "fixing hardcoded paths for $HOME"
    grep -rlF /home/wxw "$DOTFILES/config" "$DOTFILES/home" 2>/dev/null | while read -r f; do
        sed -i "s|/home/wxw|$HOME|g" "$f"
        ok "${f#"$DOTFILES"/}"
    done
}

link_configs() {
    step "linking configs ($( ((COPY)) && echo copy || echo symlink ) mode)"
    for c in "${CONFIGS[@]}"; do
        link "$DOTFILES/config/$c" "$CONFIG/$c"
    done
    link "$DOTFILES/home/.zshrc" "$HOME/.zshrc"

    # artix/dinit only: user services for pipewire (systemd starts these on its own)
    if command -v dinitctl >/dev/null && [[ ! -d /run/systemd/system ]]; then
        link "$DOTFILES/config/dinit.d" "$CONFIG/dinit.d"
    fi

    chmod +x "$DOTFILES"/config/bin/* "$DOTFILES"/config/quickshell/scripts/* \
        "$DOTFILES"/config/mango/scripts/* "$DOTFILES"/config/swaync/*.sh 2>/dev/null || true
    mkdir -p "$HOME/Pictures/Screenshots" "$HOME/wal" "$HOME/Videos"
}

set_shell() {
    if [[ $(getent passwd "$USER" | cut -d: -f7) == */zsh ]]; then return; fi
    step "default shell"
    if ask "make zsh your default shell?"; then
        chsh -s "$(command -v zsh)" && ok "shell changed, takes effect next login"
    fi
}

enable_services() {
    [[ -d /run/systemd/system ]] || return 0
    step "services"
    if systemctl is-enabled NetworkManager >/dev/null 2>&1; then
        ok "NetworkManager already enabled"
    elif ask "enable NetworkManager?"; then
        $SUDO systemctl enable --now NetworkManager && ok "NetworkManager enabled"
    fi
}

finish() {
    step "done"
    if [[ -d $BACKUP ]]; then info "your old configs are in ${BACKUP/#$HOME/\~}"; fi
    cat <<EOF

  ${B}next steps${R}
    1. log out and pick ${B}mango${R} in your display manager (or run ${B}mango${R} from a tty)
    2. drop some wallpapers in ${B}~/wal${R}
    3. press ${B}SUPER + W${R} to pick one, colors follow the wallpaper
    4. open ${B}nvim${R} once so lazy.nvim can install the plugins

EOF
}

# --------------------------------------------------------------------------
#  main
# --------------------------------------------------------------------------

while (($#)); do
    case $1 in
        -y | --yes) ASSUME_YES=1 ;;
        -c | --copy) COPY=1 ;;
        -n | --no-packages) PACKAGES=0 ;;
        -e | --extras) EXTRAS=1 ;;
        -h | --help) usage ;;
        *) die "unknown option: $1 (see --help)" ;;
    esac
    shift
done

banner
check_system
if ((PACKAGES)); then
    install_aur_helper
    install_packages
fi
fix_paths
link_configs
set_shell
if ((PACKAGES)); then enable_services; fi
finish

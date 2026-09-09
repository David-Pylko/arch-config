#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Dotfiles Installation & Setup Script
# ==============================================================================

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config_backups/backup_$(date +'%Y%m%d_%H%M%S')"

print_banner() {
    echo -e "${BOLD}${BLUE}"
    echo "  ========================================================"
    echo "       Arch Linux Dotfiles & System Setup Script          "
    echo "  ========================================================"
    echo -e "${NC}"
}

check_arch() {
    if [ ! -f /etc/arch-release ]; then
        log_warn "This script is designed for Arch Linux. Detected non-Arch system."
        read -rp "Do you still want to proceed? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_error "Aborting installation."
            exit 1
        fi
    fi
}

install_terminal_packages() {
    log_info "Installing terminal packages (fish, kitty, tmux, vim, fzf, fastfetch, git)..."
    if [ -f "$REPO_DIR/packages/terminal-pkgs.txt" ]; then
        sudo pacman -S --needed --noconfirm - < "$REPO_DIR/packages/terminal-pkgs.txt"
    else
        sudo pacman -S --needed --noconfirm fish kitty tmux vim fzf fastfetch git
    fi
    log_success "Terminal packages installed successfully."
}

install_pacman_packages() {
    if [ -f "$REPO_DIR/packages/pacman-pkgs.txt" ]; then
        log_info "Installing official pacman packages from packages/pacman-pkgs.txt..."
        sudo pacman -S --needed --noconfirm - < "$REPO_DIR/packages/pacman-pkgs.txt"
        log_success "Pacman packages installed successfully."
    else
        log_warn "packages/pacman-pkgs.txt not found, skipping official package install."
    fi
}

ensure_aur_helper() {
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    elif command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    else
        log_warn "No AUR helper (yay/paru) found. Installing 'yay'..."
        sudo pacman -S --needed --noconfirm base-devel git
        local temp_dir
        temp_dir="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay-bin.git "$temp_dir/yay-bin"
        (cd "$temp_dir/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$temp_dir"
        AUR_HELPER="yay"
        log_success "yay installed successfully."
    fi
}

install_aur_packages() {
    if [ -f "$REPO_DIR/packages/aur-pkgs.txt" ]; then
        ensure_aur_helper
        log_info "Installing AUR packages using $AUR_HELPER from packages/aur-pkgs.txt..."
        "$AUR_HELPER" -S --needed --noconfirm - < "$REPO_DIR/packages/aur-pkgs.txt"
        log_success "AUR packages installed successfully."
    else
        log_warn "packages/aur-pkgs.txt not found, skipping AUR package install."
    fi
}

backup_and_link() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        log_warn "Source does not exist: $source, skipping."
        return 0
    fi

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        local current_link
        current_link="$(readlink -f "$target")"
        if [ "$current_link" = "$(readlink -f "$source")" ]; then
            log_info "Already linked: $target -> $source"
            return 0
        fi
        log_warn "Removing outdated symlink: $target"
        rm "$target"
    elif [ -e "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        log_warn "Backing up existing: $target -> $BACKUP_DIR/"
        mv "$target" "$BACKUP_DIR/"
    fi

    ln -s "$source" "$target"
    log_success "Linked: $target -> $source"
}

link_terminal_configs() {
    log_info "Linking terminal configurations (kitty, tmux, fish, .vimrc)..."
    mkdir -p "$HOME/.config"

    # Terminal configs in ~/.config
    for app in fish kitty tmux; do
        if [ -d "$REPO_DIR/config/$app" ]; then
            backup_and_link "$REPO_DIR/config/$app" "$HOME/.config/$app"
        fi
    done

    # .vimrc in ~/
    if [ -f "$REPO_DIR/home/.vimrc" ]; then
        backup_and_link "$REPO_DIR/home/.vimrc" "$HOME/.vimrc"
    fi
}

link_desktop_configs() {
    log_info "Linking desktop configurations (hypr, waybar, mako, rofi, wofi)..."
    mkdir -p "$HOME/.config"

    for app in hypr waybar mako rofi wofi; do
        if [ -d "$REPO_DIR/config/$app" ]; then
            backup_and_link "$REPO_DIR/config/$app" "$HOME/.config/$app"
        fi
    done
}

link_all_configs() {
    link_terminal_configs
    link_desktop_configs
}

set_default_shell() {
    if command -v fish >/dev/null 2>&1; then
        local fish_path
        fish_path="$(which fish)"
        if [ "${SHELL:-}" != "$fish_path" ]; then
            read -rp "Set fish ($fish_path) as your default shell? [y/N]: " change_shell
            if [[ "$change_shell" =~ ^[Yy]$ ]]; then
                chsh -s "$fish_path"
                log_success "Default shell set to fish."
            fi
        fi
    fi
}

show_backup_location() {
    if [ -d "$BACKUP_DIR" ]; then
        echo
        log_info "Existing configs were safely backed up to: $BACKUP_DIR"
    fi
}

show_help() {
    echo "Usage: ./install.sh [OPTION]"
    echo
    echo "Options:"
    echo "  --all                    Full setup (all packages + all configs + shell prompt)"
    echo "  --terminal               Terminal setup (terminal packages + kitty, tmux, fish, vim configs)"
    echo "  --terminal-links         Only link terminal configs (kitty, tmux, fish, .vimrc)"
    echo "  --desktop-links          Only link desktop configs (hypr, waybar, mako, rofi, wofi)"
    echo "  --links-only             Link all configs (desktop + terminal)"
    echo "  --packages-only          Install all official & AUR packages"
    echo "  --terminal-packages-only Install only terminal packages"
    echo "  --help, -h               Show this help message"
}

# Main execution logic
print_banner
check_arch

MODE="${1:-}"

case "$MODE" in
    --all)
        install_pacman_packages
        install_aur_packages
        link_all_configs
        set_default_shell
        show_backup_location
        ;;
    --terminal|--terminal-only)
        install_terminal_packages
        link_terminal_configs
        set_default_shell
        show_backup_location
        ;;
    --terminal-links|--terminal-configs-only)
        link_terminal_configs
        show_backup_location
        ;;
    --desktop-links|--desktop-configs-only)
        link_desktop_configs
        show_backup_location
        ;;
    --links-only)
        link_all_configs
        show_backup_location
        ;;
    --packages-only)
        install_pacman_packages
        install_aur_packages
        ;;
    --terminal-packages-only)
        install_terminal_packages
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    *)
        echo -e "${BOLD}Select installation option:${NC}"
        echo "1) Full Setup (All packages + All configs + Shell setup)"
        echo "2) Terminal Setup Only (Terminal packages + Kitty, Tmux, Fish, Vim configs)"
        echo "3) Terminal Configs Only (Link Kitty, Tmux, Fish, Vim without packages)"
        echo "4) Desktop Configs Only (Link Hyprland, Waybar, Rofi, Wofi, Mako configs)"
        echo "5) Link All Configs Only (Desktop + Terminal configs without packages)"
        echo "6) Install All Packages Only (Official pacman + AUR)"
        echo "7) Exit"
        echo
        read -rp "Choice [1-7]: " choice
        case "$choice" in
            1)
                install_pacman_packages
                install_aur_packages
                link_all_configs
                set_default_shell
                show_backup_location
                ;;
            2)
                install_terminal_packages
                link_terminal_configs
                set_default_shell
                show_backup_location
                ;;
            3)
                link_terminal_configs
                show_backup_location
                ;;
            4)
                link_desktop_configs
                show_backup_location
                ;;
            5)
                link_all_configs
                show_backup_location
                ;;
            6)
                install_pacman_packages
                install_aur_packages
                ;;
            *)
                log_info "Exiting without making changes."
                exit 0
                ;;
        esac
        ;;
esac

echo
log_success "Installation routine finished!"

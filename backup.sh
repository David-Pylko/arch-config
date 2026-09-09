#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Dotfiles Backup Script (Local Sync Only)
# ==============================================================================
# Refreshes package lists and syncs local configuration files without
# pushing to GitHub, allowing you to review or edit before pushing.

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

echo -e "${BOLD}${BLUE}=== Backing Up Dotfiles Locally ===${NC}"

# Ensure required directories exist
mkdir -p "$REPO_DIR/packages" "$REPO_DIR/config" "$REPO_DIR/home"

# 1. Update official and AUR package lists
log_info "Updating package lists..."
if command -v pacman >/dev/null 2>&1; then
    pacman -Qqen > "$REPO_DIR/packages/pacman-pkgs.txt"
    pacman -Qqem > "$REPO_DIR/packages/aur-pkgs.txt"
    log_success "Exported $(wc -l < "$REPO_DIR/packages/pacman-pkgs.txt") pacman packages and $(wc -l < "$REPO_DIR/packages/aur-pkgs.txt") AUR packages."
else
    log_warn "pacman command not found, skipping package list update."
fi

# 2. Sync configs from system if they are regular directories (not symlinks)
sync_config_dir() {
    local app="$1"
    local system_path="$HOME/.config/$app"
    local repo_path="$REPO_DIR/config/$app"

    if [ -d "$system_path" ]; then
        if [ -L "$system_path" ]; then
            log_info "Config '~/.config/$app' is symlinked directly to repo."
        else
            log_info "Copying '~/.config/$app' into repo..."
            mkdir -p "$repo_path"
            cp -a "$system_path/." "$repo_path/"
        fi
    fi
}

sync_home_file() {
    local filename="$1"
    local system_path="$HOME/$filename"
    local repo_path="$REPO_DIR/home/$filename"

    if [ -f "$system_path" ]; then
        if [ -L "$system_path" ]; then
            log_info "File '~/$filename' is symlinked directly to repo."
        else
            log_info "Copying '~/$filename' into repo..."
            cp -a "$system_path" "$repo_path"
        fi
    fi
}

log_info "Checking configuration files..."
sync_home_file ".vimrc"

for app in fish hypr kitty mako rofi tmux waybar wofi; do
    sync_config_dir "$app"
done

# 3. Clean transient, backup, and log files
find "$REPO_DIR/config" -type f \( -name "*.bak" -o -name "*.old" -o -name "nohup.out" -o -name "touchpad.status" -o -name "fish_variables" \) -delete 2>/dev/null || true

echo
# 4. Show status of local changes
if [ -d "$REPO_DIR/.git" ]; then
    if [ -z "$(git status --porcelain)" ]; then
        log_success "Backup complete. No changes detected compared to last commit."
    else
        log_info "Local changes ready for review:"
        git status -s
        echo
        echo -e "${YELLOW}Tip:${NC} You can now review or edit files (e.g. packages/pacman-pkgs.txt)."
        echo -e "When ready to commit and push to GitHub, run:"
        echo -e "  ${BOLD}./push.sh [optional commit message]${NC}"
    fi
else
    log_success "Backup complete. (Git repository not yet initialized)."
    echo -e "Run ${BOLD}./push.sh${NC} to initialize git and push to GitHub."
fi


#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Dotfiles GitHub Push Script
# ==============================================================================
# Stages all local changes, commits with a message, and pushes to GitHub.

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

echo -e "${BOLD}${BLUE}=== Pushing Dotfiles to GitHub ===${NC}"

# 1. Initialize git if not already initialized
if [ ! -d "$REPO_DIR/.git" ]; then
    log_warn "Git repository not initialized in $REPO_DIR."
    read -rp "Initialize git repository now? [Y/n]: " init_git
    if [[ ! "$init_git" =~ ^[Nn]$ ]]; then
        git init
        git branch -M main
        log_success "Initialized git repository (branch: main)."
    else
        log_error "Cannot commit or push without git. Exiting."
        exit 1
    fi
fi

CURRENT_BRANCH="$(git branch --show-current 2>/dev/null || echo "main")"
HAS_CHANGES=false

if [ -n "$(git status --porcelain)" ]; then
    HAS_CHANGES=true
fi

# 2. Stage and commit changes if present
if [ "$HAS_CHANGES" = true ]; then
    echo
    log_info "Uncommitted changes:"
    git status -s
    echo

    DEFAULT_MSG="Dotfiles update: $(date +'%Y-%m-%d %H:%M:%S')"
    COMMIT_MSG="${1:-}"

    if [ -z "$COMMIT_MSG" ]; then
        read -rp "Enter commit message (Press Enter for '${DEFAULT_MSG}'): " input_msg
        COMMIT_MSG="${input_msg:-$DEFAULT_MSG}"
    fi

    git add -A
    git commit -m "$COMMIT_MSG"
    log_success "Committed changes: \"$COMMIT_MSG\""
else
    log_info "No uncommitted local changes."
fi

# 3. Check for unpushed commits and push to remote
if git remote | grep -q "^origin$"; then
    log_info "Pushing to remote 'origin' ($CURRENT_BRANCH)..."
    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
        git push
    else
        git push -u origin "$CURRENT_BRANCH"
    fi
    echo
    log_success "Successfully pushed dotfiles to GitHub!"
else
    echo
    log_warn "No git remote 'origin' configured yet."
    echo -e "${YELLOW}To link this repository to GitHub, run:${NC}"
    echo "  git remote add origin git@github.com:<YOUR_USERNAME>/<YOUR_REPO>.git"
    echo "  git push -u origin $CURRENT_BRANCH"
fi


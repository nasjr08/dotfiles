#!/usr/bin/env bash
# bootstrap.sh — provision a fresh Mac from this dotfiles repo.
# Usage (on the target Mac, after signing into Apple ID and 1Password):
#   curl -fsSL https://raw.githubusercontent.com/<GH_USER>/dotfiles/main/bootstrap.sh | bash

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-git@github.com:<GH_USER>/dotfiles.git}"
LOG="$HOME/.bootstrap.log"
BACKUP_DIR="$HOME/.bootstrap-backup-$(date +%Y%m%d-%H%M%S)"

log() { printf '[bootstrap] %s\n' "$*" | tee -a "$LOG" >&2; }

backup_if_exists() {
    local path="$1"
    if [[ -e "$path" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -a "$path" "$BACKUP_DIR/"
        log "backed up $path -> $BACKUP_DIR/"
    fi
}

main() {
    : > "$LOG"
    log "starting bootstrap on $(sw_vers -productName) $(sw_vers -productVersion) ($(uname -m))"

    # 1. Xcode Command Line Tools
    if ! xcode-select -p >/dev/null 2>&1; then
        log "installing Xcode Command Line Tools (a GUI prompt will appear)"
        xcode-select --install || true
        until xcode-select -p >/dev/null 2>&1; do
            sleep 10
            log "waiting for Xcode CLT install to finish..."
        done
    else
        log "Xcode Command Line Tools already present"
    fi

    # 2. Homebrew
    if ! command -v brew >/dev/null 2>&1; then
        log "installing Homebrew"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log "Homebrew already present"
    fi
    # Ensure brew is on PATH for the rest of this script
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # 3. Prereq packages
    log "installing chezmoi, 1password-cli, mas via Homebrew"
    brew install chezmoi 1password-cli mas

    # 4. 1Password CLI signin
    if ! op account list >/dev/null 2>&1; then
        log "no 1Password account configured for op — opening interactive signin"
        log "(make sure the 1Password desktop app is running and 'Integrate with 1Password CLI' is enabled)"
        op signin
    else
        log "1Password CLI already signed in"
    fi

    # 5. Back up anything chezmoi might overwrite
    for f in ~/.zshrc ~/.gitconfig ~/.ssh/config ~/.aws/credentials; do
        backup_if_exists "$f"
    done

    # 6. chezmoi init + apply
    log "running chezmoi init --apply $DOTFILES_REPO"
    chezmoi init --apply "$DOTFILES_REPO"

    log "bootstrap complete. Log: $LOG. Backups (if any): $BACKUP_DIR"
}

main "$@"

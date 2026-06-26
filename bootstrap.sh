#!/usr/bin/env bash
# bootstrap.sh — provision a fresh Mac from this dotfiles repo.
# Usage (on the target Mac, after signing into Apple ID and 1Password):
#   curl -fsSL https://raw.githubusercontent.com/nasjr08/dotfiles/main/bootstrap.sh | bash

set -euo pipefail

# Use HTTPS for the initial clone so a fresh Mac can bootstrap without any
# pre-existing GitHub SSH auth. Once chezmoi apply has written
# ~/.config/1Password/ssh/agent.toml and 1Password has been restarted, SSH is
# available for daily work. If you want to push from this Mac later, switch
# the remote:
#     chezmoi cd
#     git remote set-url origin git@github.com:nasjr08/dotfiles.git
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/nasjr08/dotfiles.git}"
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

    # Guard: catch un-substituted repo URL (Step 12.6 of the setup plan).
    if [[ "$DOTFILES_REPO" == *"<GH_USER>"* ]]; then
        echo "[bootstrap] ERROR: DOTFILES_REPO still contains the literal token <GH_USER>." >&2
        echo "[bootstrap]   You must substitute your GitHub username before running this script." >&2
        echo "[bootstrap]   See plan Step 12.6: sed -i '' 's/<GH_USER>/YOUR_USERNAME/g' bootstrap.sh" >&2
        exit 1
    fi

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
    # chezmoi will fail with a clear error if GitHub SSH isn't configured —
    # no need for a separate brittle precheck here.
    log "running chezmoi init --apply $DOTFILES_REPO"
    chezmoi init --apply "$DOTFILES_REPO"

    log "bootstrap complete. Log: $LOG. Backups (if any): $BACKUP_DIR"

    # Surface the manual-tweaks runbook — settings that have to be applied by
    # hand (iTerm2 keybindings, hotkey windows, etc.). Bold + a blank line on
    # each side so it doesn't get lost in the brew/mas output above.
    printf '\n\033[1m============================================================\033[0m\n'
    printf '\033[1mNEXT: apply the manual UI tweaks listed in:\033[0m\n'
    printf '  • local: ~/.local/share/chezmoi/docs/manual-settings.md\n'
    printf '  • web:   https://github.com/nasjr08/dotfiles/blob/main/docs/manual-settings.md\n'
    printf 'Add to that file whenever you find a new setting that can'\''t be\n'
    printf 'automated, so the next fresh Mac has a complete runbook.\n'
    printf '\033[1m============================================================\033[0m\n\n'
}

main "$@"

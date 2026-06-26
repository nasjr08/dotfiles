#!/usr/bin/env bash
# Install oh-my-zsh if not present. dot_zshrc.tmpl sources it unconditionally,
# so without this script a fresh Mac will hit a missing-file error in the very
# first shell after `chezmoi apply`.
#
# Uses the official unattended installer.

set -euo pipefail

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "[oh-my-zsh] already installed at $HOME/.oh-my-zsh, skipping"
    exit 0
fi

echo "[oh-my-zsh] installing (unattended)"
# RUNZSH=no       — don't drop into zsh after install
# CHSH=no         — don't try to switch the default shell (macOS already uses zsh)
# KEEP_ZSHRC=yes  — don't touch ~/.zshrc (chezmoi owns it)
RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "[oh-my-zsh] done"

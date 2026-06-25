#!/usr/bin/env bash
# macos/defaults.sh — opinionated macOS system preferences.
# Safe to re-run (every `defaults write` is idempotent).
# Curated from https://macos-defaults.com and personal preference.

set -euo pipefail

echo "[defaults] applying macOS system preferences..."

############################################################
# Dock
############################################################
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.4
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock mineffect -string "scale"

############################################################
# Finder
############################################################
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"   # List view
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true          # show dotfiles
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search current folder

############################################################
# Keyboard + trackpad
############################################################
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false   # disable accent menu, enable key repeat
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

############################################################
# Screenshots
############################################################
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

############################################################
# Misc
############################################################
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001         # faster window resize

# Restart affected services so changes take effect
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "[defaults] done. Some changes require log-out to fully apply."

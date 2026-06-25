#!/usr/bin/env bash
# capture.sh — refresh the easily-automatable parts of the dotfiles repo
# from the current Mac's state. Run any time you want to sync the repo
# with what's actually installed.
#
# Things it refreshes automatically:
#   - editors/vscode-extensions.txt
#   - editors/vscode-settings.jsonc
#   - editors/cursor-extensions.txt
#   - editors/cursor-settings.jsonc
#
# Things it dumps for manual curation (NOT auto-applied):
#   - /tmp/Brewfile.full — review and merge wanted entries into packages/Brewfile
#   - /tmp/mas-apps.list — review and merge wanted mas entries into packages/Brewfile (or a flavor Brewfile)

set -euo pipefail

REPO="${REPO:-$HOME/Dev/dotfiles}"
[[ -d "$REPO" ]] || { echo "REPO not found: $REPO" >&2; exit 1; }

echo "[capture] refreshing editors/"
if command -v code >/dev/null 2>&1; then
    code --list-extensions > "$REPO/editors/vscode-extensions.txt"
fi
VSC_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
[[ -f "$VSC_SETTINGS" ]] && cp "$VSC_SETTINGS" "$REPO/editors/vscode-settings.jsonc"

if command -v cursor >/dev/null 2>&1; then
    cursor --list-extensions > "$REPO/editors/cursor-extensions.txt"
fi
CURSOR_SETTINGS="$HOME/Library/Application Support/Cursor/User/settings.json"
[[ -f "$CURSOR_SETTINGS" ]] && cp "$CURSOR_SETTINGS" "$REPO/editors/cursor-settings.jsonc"

echo "[capture] dumping mas app list to /tmp/mas-apps.list (NOT auto-merged)"
if command -v mas >/dev/null 2>&1; then
    mas list | awk '{print $1, substr($0, index($0,$2))}' > /tmp/mas-apps.list
    echo "[capture] review /tmp/mas-apps.list and manually merge wanted mas \"App Name\", id: NNNNN lines into packages/Brewfile (or a flavor Brewfile)"
fi

echo "[capture] dumping current full Brewfile to /tmp/Brewfile.full (NOT auto-merged)"
brew bundle dump --file=/tmp/Brewfile.full --force

echo "[capture] showing diff vs the repo's curated Brewfile (manually merge wanted lines):"
diff -u "$REPO/packages/Brewfile" /tmp/Brewfile.full | head -100 || true

echo
echo "[capture] secret scan of refreshed files"
if grep -rIE 'sk-[a-zA-Z0-9_-]{20,}|ghp_[a-zA-Z0-9]{30,}|AKIA[0-9A-Z]{16}' \
    "$REPO/editors/" "$REPO/packages/" 2>/dev/null; then
    echo "[capture] WARNING: potential secrets above — DO NOT commit until removed." >&2
    exit 1
fi

echo "[capture] done. Review with: git -C $REPO status"

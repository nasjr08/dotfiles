#!/usr/bin/env bash
# verify-op-paths.sh — confirm each op:// path used by chezmoi templates resolves.
# Edit the PATHS array below as you add new items to 1Password.

set -uo pipefail

VAULT="${OP_VAULT:-Work}"

PATHS=(
    # Required for bootstrap (GitHub SSH access).
    "op://${VAULT}/${VAULT} GitHub SSH/public key"

    # Uncomment as you create the items in 1Password (see docs/1password-setup.md):
    # "op://${VAULT}/${VAULT} AWS – default/access_key"
    # "op://${VAULT}/${VAULT} AWS – default/secret_key"
    # "op://${VAULT}/OpenAI/credential"
    # "op://${VAULT}/Anthropic/credential"
)

if ! command -v op >/dev/null 2>&1; then
    echo "FAIL: 'op' CLI not installed. Run: brew install 1password-cli" >&2
    exit 1
fi

if ! op vault list >/dev/null 2>&1; then
    echo "FAIL: 'op' cannot reach a 1Password account." >&2
    echo "  - If you're using the desktop app: open 1Password, Settings -> Developer," >&2
    echo "    enable 'Integrate with 1Password CLI', then retry." >&2
    echo "  - Otherwise: run 'op signin'." >&2
    exit 1
fi

fail=0
for path in "${PATHS[@]}"; do
    if op read "$path" >/dev/null 2>&1; then
        printf "  OK   %s\n" "$path"
    else
        printf "  FAIL %s\n" "$path"
        fail=1
    fi
done

if [[ $fail -ne 0 ]]; then
    echo "One or more paths failed. Check item names/fields in 1Password against docs/1password-setup.md." >&2
    exit 1
fi
echo "All paths OK."

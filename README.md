# dotfiles

Mac setup automation. One command provisions a fresh Mac with shell config, CLI tools, GUI apps, editor configs, macOS defaults, and credentials via 1Password.

## Bootstrap a fresh Mac

### Prerequisites (manual, ~5 min)

1. Sign into Apple ID and iCloud Keychain (System Settings).
2. Install [1Password](https://1password.com/downloads/mac), sign in.
3. In 1Password Settings → Developer, enable **Use the SSH agent** and **Integrate with 1Password CLI**.
4. Follow `docs/1password-setup.md` to create the `Work` vault and required items.
5. Add the public SSH key from the Work vault to your work GitHub account.

### Bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/nasjr08/dotfiles/main/bootstrap.sh | bash
```

On first run you'll be prompted for:
- `flavor` — `work` or `personal`
- `fullName`, `email` — for git config
- `op_vault` — 1Password vault name (e.g., `Work`)

Total time: ~30–45 minutes (Homebrew and Mac App Store downloads), ~10 min active.

## Ongoing usage

| Situation | Command |
|---|---|
| Edit dotfile, commit change | `chezmoi edit ~/.zshrc` then `chezmoi cd && git commit -am '...' && git push` |
| Add a new brew | edit `packages/Brewfile`, `chezmoi apply` re-runs `brew bundle` |
| Pull latest changes | `chezmoi update` |
| Preview pending changes | `chezmoi diff` |
| Refresh captured state from current Mac | `scripts/capture.sh` |
| Verify 1Password paths still resolve | `scripts/verify-op-paths.sh` |

## Layout

See `docs/superpowers/specs/2026-06-25-mac-setup-design.md` for the full design. Quick reference:

- Dotfiles at repo root (`dot_*`, `private_*`, `*.tmpl`) — managed by chezmoi.
- `packages/` — Brewfile (common + work + personal).
- `editors/` — Cursor extensions and settings. (VS Code captures are wired into the lifecycle scripts but not currently committed — the source Mac doesn't have VS Code installed.)
- `macos/` — `defaults.sh` for system preferences.
- `.chezmoiscripts/` — lifecycle scripts chezmoi runs automatically.
- `scripts/` — helpers (`capture.sh`, `verify-op-paths.sh`).
- `docs/` — design spec, plan, 1Password setup runbook.

## Troubleshooting

- **`op read` errors during apply** — 1Password CLI not signed in. Run `op signin`, then re-run `chezmoi apply`.
- **`brew bundle` fails on one cask** — usually a transient download issue or the cask requires admin password. The command continues past failures; re-run `chezmoi apply` after fixing.
- **VS Code / Cursor extensions don't install** — the `code` / `cursor` CLI isn't on PATH. Open the app, `Cmd+Shift+P` → "Install code in PATH" / "Install cursor command in PATH". Then `chezmoi apply` again.
- **Bootstrap interrupted** — `chezmoi apply` is idempotent. Re-run safely.

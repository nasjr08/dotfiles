# Mac Setup Automation — Design

**Date:** 2026-06-25
**Author:** Naseer Basma (with Claude)
**Status:** Approved, ready for implementation plan

## Goal

Build a reusable, version-controlled setup that brings a fresh Mac to a fully-configured state — shell, CLI tools, GUI apps, editor configs, macOS defaults, and credentials — with one bootstrap command. Designed first for migrating from the current personal Mac to a new work Mac, then reusable for any future Mac.

## Constraints & assumptions

- **Source Mac:** Apple Silicon, macOS 15.3.1, zsh + oh-my-zsh, Homebrew already installed, no existing dotfiles repo.
- **Target Mac:** new work-issued Mac, Apple Silicon assumed, MDM-managed but user has admin (can `sudo`, can install via Homebrew).
- **Mixed-use source:** the current Mac holds both personal and contract/work-related material. The setup must cleanly separate the two so the work Mac gets work things only.
- **Credentials strategy:** user is adopting 1Password as part of this migration. No prior password manager to migrate from.
- **Hosting:** dotfiles repo is a private GitHub repo (e.g., `naseerjr/dotfiles`).

## Stack

| Layer | Choice | Why |
|---|---|---|
| Dotfiles manager | **chezmoi** | Native 1Password templating, per-machine variation via Go templates, idempotent apply, lifecycle scripts |
| Package management | **Homebrew + `brew bundle`** | Standard on macOS; `Brewfile` captures CLI tools, casks, and Mac App Store apps in one file (via `mas`) |
| Credential store | **1Password + `op` CLI + 1Password SSH agent** | SSH keys live in vault (never on disk), other secrets pulled at apply time via `op read` or `onepasswordRead` template function |
| Mac App Store automation | **`mas` CLI** | Allows scripted install of App Store apps |
| Editor configs | **Plain files in repo + extension list** | `code --install-extension` / `cursor --install-extension` per line in `*-extensions.txt`; settings.json copied verbatim |
| macOS defaults | **`defaults write` script** | Run as a chezmoi `run_onchange_after_*` script |

Rejected alternatives:
- **yadm** — simpler but lacks native 1Password integration; credential handling becomes the hard part.
- **GNU stow + plain git** — most minimal but every per-machine variation is a manual conditional; too much hand-maintenance.

## Repo layout

```
dotfiles/                           # → github.com/naseerjr/dotfiles (private)
├── README.md                       # bootstrap instructions for a fresh Mac
├── bootstrap.sh                    # curl|bash entry point
├── .chezmoi.toml.tmpl              # prompts on first apply (flavor, email, etc.)
│
├── home/                           # → mirrors ~ on target
│   ├── dot_zshrc.tmpl              # → ~/.zshrc (templated for per-flavor env vars)
│   ├── dot_gitconfig.tmpl          # → ~/.gitconfig (work vs personal email)
│   ├── dot_config/                 # → ~/.config/...
│   ├── private_dot_ssh/
│   │   └── config.tmpl             # → ~/.ssh/config (0600), points at 1Password agent
│   ├── private_dot_aws/
│   │   └── credentials.tmpl        # → ~/.aws/credentials (0600), templated from 1Password
│   ├── dot_claude/                 # → ~/.claude (settings only, secrets via op)
│   └── dot_codex/                  # → ~/.codex (same)
│
├── packages/
│   ├── Brewfile                    # common to all machines
│   ├── Brewfile.work.tmpl          # work-only (conditional on flavor)
│   ├── Brewfile.personal.tmpl      # personal-only (placeholder for future use)
│   └── mas-apps.txt                # Mac App Store IDs (referenced from Brewfile)
│
├── editors/
│   ├── vscode-extensions.txt
│   ├── vscode-settings.jsonc
│   ├── cursor-extensions.txt
│   └── cursor-settings.jsonc
│
├── macos/
│   └── defaults.sh                 # `defaults write ...` tweaks
│
└── scripts/                        # chezmoi auto-runs by name convention
    ├── run_onchange_before_install-prereqs.sh
    ├── run_onchange_install-brews.sh
    ├── run_onchange_install-vscode-extensions.sh
    ├── run_onchange_install-cursor-extensions.sh
    └── run_onchange_after_macos-defaults.sh
```

chezmoi naming conventions used:
- `dot_<name>` → installed as `~/.<name>`
- `private_<name>` → installed with mode `0600`
- `*.tmpl` → rendered as Go template at apply time
- `run_onchange_<order>_<name>.sh` → executed when content hash changes; `before_` runs before file install, `after_` runs after

## Bootstrap flow on new Mac

Manual prerequisites (one-time, ~5 min):

1. Sign in to Apple ID (System Settings) — required for Mac App Store.
2. Sign in to iCloud Keychain (restores Wi-Fi etc.).
3. Install 1Password desktop app, sign in to account.
4. In 1Password Settings → Developer, enable **Use the SSH agent** and **Integrate with 1Password CLI**.

Then a single command does the rest:

```bash
curl -fsSL https://raw.githubusercontent.com/naseerjr/dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` performs in order:
1. Install Xcode Command Line Tools (`xcode-select --install`).
2. Install Homebrew via the official installer.
3. `brew install chezmoi 1password-cli mas`.
4. Run `op signin` interactively to authenticate the CLI.
5. `chezmoi init --apply git@github.com:naseerjr/dotfiles.git`.

`chezmoi apply` then:
1. Reads `.chezmoi.toml.tmpl` and prompts the user once for: flavor (`work` / `personal`), git user name + email, 1Password vault name. Caches answers in `~/.config/chezmoi/chezmoi.toml`.
2. Renders all `.tmpl` files using cached answers + `op read` calls for 1Password references.
3. Writes files to `~/` with correct permissions.
4. Runs `run_onchange_before_*` scripts (prereqs already installed by `bootstrap.sh`; this script is mostly a no-op safety net).
5. Runs `run_onchange_install-brews.sh` → `brew bundle --file=packages/Brewfile` and conditionally `brew bundle --file=packages/Brewfile.work` if `flavor == "work"`.
6. Runs `run_onchange_install-{vscode,cursor}-extensions.sh` → installs from `*-extensions.txt`.
7. Runs `run_onchange_after_macos-defaults.sh` → applies opinionated Dock/Finder/trackpad/keyboard tweaks.

Safety net: `bootstrap.sh` writes a log to `~/.bootstrap.log` and snapshots any pre-existing files it's about to overwrite into `~/.bootstrap-backup-<timestamp>/`.

Idempotency: `chezmoi apply` can be re-run safely; failed individual `brew install` does not abort the run.

Estimated time: ~30–45 min total (mostly Homebrew + App Store downloads), ~10 min of active keyboard time.

## Per-machine templating (work vs personal)

Two flavors initially: `work`, `personal`. (A third flavor for client-specific contract work was considered and deferred — re-evaluate if needed.)

### Machine-local config (not in git)

`~/.config/chezmoi/chezmoi.toml`:
```toml
[data]
    flavor   = "work"
    email    = "naseer@<company>.com"
    fullName = "Naseer Basma"
    op_vault = "Work"
```

Generated by the first-run prompt from `.chezmoi.toml.tmpl`.

### Example templates

`home/dot_gitconfig.tmpl`:
```gotmpl
[user]
    name  = {{ .fullName | quote }}
    email = {{ .email | quote }}

[core]
    editor = nvim

{{ if eq .flavor "work" -}}
[url "git@github.com-work:"]
    insteadOf = git@github.com:<work-org>/
{{- end }}
```

`home/private_dot_ssh/config.tmpl`:
```gotmpl
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    AddKeysToAgent yes

{{ if eq .flavor "work" -}}
Host github.com-work
    HostName github.com
    User git
    IdentitiesOnly yes
{{- end }}
```

`packages/Brewfile.work.tmpl`:
```gotmpl
{{ if eq .flavor "work" -}}
cask "slack"
cask "zoom"
brew "kubectl"
brew "awscli"
{{- end }}
```

### Three-tier separation

- **Repo (git):** structure, templates, tool lists, public configs. Safe to push.
- **Machine-local config (`~/.config/chezmoi/chezmoi.toml`):** flavor, identity, vault names. NOT committed.
- **1Password vault:** actual secrets. Referenced from templates by `op://...` paths.

## Credential handling

### 1Password vault structure

```
Personal vault (default)
└── Personal GitHub SSH       (SSH Key item)
    Personal AWS              (API Credential)
    ... personal stuff

Work vault (create as part of one-time setup)
└── Work GitHub SSH           (SSH Key item)
    Work AWS – default        (API Credential, fields: access_key, secret_key)
    Work GitHub PAT           (API Credential)
    OpenAI / Anthropic keys   (whatever work AI tooling needs)
    ... add as needed
```

Templates choose vault by `.op_vault` (set per machine).

### Three patterns

**Pattern A — SSH keys via 1Password SSH agent.** Generate inside 1Password (`op item create --category=ssh-key --ssh-generate-key=ed25519`). Public key copied into GitHub / target service. Private key never leaves vault. SSH config (Section above) points at the 1Password agent socket. Nothing to do on new Mac except sign into 1Password.

**Pattern B — Templated files (e.g., `~/.aws/credentials`).** chezmoi template references `op://...` paths; `chezmoi apply` calls `op read`; result written to disk with `private_` permissions. Re-apply re-fetches (so rotating in 1Password and re-applying updates the file).

```gotmpl
# home/private_dot_aws/credentials.tmpl
[default]
aws_access_key_id     = {{ onepasswordRead (print "op://" .op_vault "/Work AWS – default/access_key") }}
aws_secret_access_key = {{ onepasswordRead (print "op://" .op_vault "/Work AWS – default/secret_key") }}
{{ if eq .flavor "work" -}}
region                = eu-west-2
{{- end }}
```

**Pattern C — Env vars in shell.** For API keys consumed via env at runtime, source from `op read --cache`. The vault name is baked in at chezmoi apply time via `.op_vault`:

```gotmpl
# in home/dot_zshrc.tmpl
{{ if eq .flavor "work" -}}
export OPENAI_API_KEY="$(op read 'op://{{ .op_vault }}/OpenAI/credential' --cache 2>/dev/null)"
{{- end }}
```

Caveat: a small per-shell cost. If unacceptable, switch to a chezmoi-managed `~/.config/secrets.env` (Pattern B) and `source` it.

### One-time prep on source Mac

- Create "Work" vault in 1Password.
- Move/create work-relevant items there.
- For each item, note the exact `op://Vault/Item/field` path.
- Verify each: `op read 'op://Work/Item/field'` prints the value.
- Add public SSH key to work GitHub account.

### Out of scope for the bootstrap

- App sign-ins (Slack, Cursor account, browser logins) — manual on new Mac.
- Browser cookies / sessions — browser sync handles them.
- iCloud-managed content (iMessage, Photos) — Apple ID sign-in handles them.

## Capture, maintenance, testing

### Initial capture (one-time on source Mac)

A `scripts/capture.sh` automates the mechanical parts; user curates the output before first commit.

| Item | Command | Curation |
|---|---|---|
| Brewfile (raw dump) | `brew bundle dump --describe --file=packages/Brewfile.full` | **Required** — split into common / work / personal |
| Mac App Store apps | `mas list \| awk '{print $1, $2}' > packages/mas-apps.txt` | Light — drop personal-only |
| VS Code extensions | `code --list-extensions > editors/vscode-extensions.txt` | Light |
| Cursor extensions | `cursor --list-extensions > editors/cursor-extensions.txt` | Light |
| VS Code settings | copy `~/Library/Application Support/Code/User/settings.json` | None |
| Cursor settings | same for Cursor | None |
| zshrc / gitconfig | `chezmoi add ~/.zshrc ~/.gitconfig` | None |
| `~/.claude` | `chezmoi add ~/.claude`, then redact secrets manually | **Required** — secrets → 1Password |
| `~/.codex` | same | **Required** |
| macOS defaults | curated list from https://macos-defaults.com plus personal preferences | **Required** |

### Ongoing maintenance

| Situation | Command |
|---|---|
| Edited live file, want to commit it back | `chezmoi re-add <path>` then commit in `chezmoi cd` |
| Added a brew/cask to be installed everywhere | Edit `packages/Brewfile`, commit, push |
| Pulled changes from repo and want to apply | `chezmoi update` (= `git pull && chezmoi apply`) |
| Preview pending changes | `chezmoi diff` |

### Testing

1. **Template lint:** `chezmoi execute-template < some.tmpl` to render with local data.
2. **Dry run:** `chezmoi apply --dry-run --verbose` shows actions without writing.
3. **Full-fidelity VM:** UTM or Tart on Apple Silicon — recommended once before bootstrap day, not for routine changes.

## Open questions / deferred decisions

- **Third "contract" flavor**: not in v1, can add later via new template branches.
- **Sharing with team via 1Password Shared vault**: not in scope for v1; structure permits adding later.
- **Bootstrapping without a `Work` vault** (e.g., first-time runs): one-time prep checklist must be completed before bootstrap; the script will fail loudly if a referenced `op://` path is missing.

## Success criteria

- Bootstrap command on a fresh work Mac completes in under 60 minutes wall-clock and under 15 minutes active user time.
- After bootstrap, `git push` to work GitHub works via 1Password SSH agent with no on-disk private keys.
- `~/.aws/credentials` exists with mode `0600` and correct values.
- VS Code / Cursor open with all curated extensions installed.
- Re-running the bootstrap on the work Mac after editing `Brewfile` adds the new tool with no manual intervention beyond `chezmoi update`.
- Personal-flavor secrets (personal SSH key, personal AWS) never appear on the work Mac.

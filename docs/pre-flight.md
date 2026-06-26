# Pre-flight runbook

Before bootstrapping a new Mac (especially a new work Mac), do this from your current/source Mac. The whole point is to surface auth and config problems while you still have a working machine.

## On the source Mac (do today)

### 1. Confirm 1Password CLI + SSH agent are healthy

```bash
op account list                              # should list at least one account
op vault list | grep -E '^Work|^Personal'    # should show both vaults
echo $SSH_AUTH_SOCK                          # should point at 1Password's agent.sock
```

If `Work` is missing → 1Password app → vault dropdown → New Vault → name it exactly `Work`. If `SSH_AUTH_SOCK` doesn't point at 1Password: 1Password Settings → Developer → enable **Use the SSH agent**, then restart your terminal.

### 2. Create both Work SSH keys in 1Password

In the 1Password **desktop app** (the CLI can't generate SSH keys):

- New item → SSH Key → Title `Work GitHub SSH` → Vault `Work` → Add Private Key → Generate → **Ed25519** → Save.
- New item → SSH Key → Title `Work GitLab SSH` → Vault `Work` → Add Private Key → Generate → **Ed25519** → Save.

Titles are exact — `scripts/verify-op-paths.sh` greps for these names.

> **About the SSH agent allow-list**: creating an SSH-Key item in 1Password does NOT automatically expose it to the SSH agent — the agent only serves items listed in `~/.config/1Password/ssh/agent.toml`. This repo manages that file (see `dot_config/1Password/ssh/agent.toml.tmpl`), so `chezmoi apply` will write the allow-list for you. If you ever need to do it manually (e.g., before chezmoi has run, or after a manual edit you want to undo) → open the item in 1Password → click **Open SSH Agent Config File…** in the purple banner → save → **restart the 1Password app**. See the troubleshooting section at the bottom for the symptoms that signal this is the problem.

### 3. Register `Work GitHub SSH` on github.com

```bash
op item get 'Work GitHub SSH' --vault='Work' --fields 'public key' | pbcopy
```

github.com → Settings → SSH and GPG keys → New SSH key → paste → title "Work Mac via 1Password" → Add.

Test:

```bash
ssh -T git@github.com
```

Touch ID prompt → `Hi nasjr08! You've successfully authenticated...`

### 4. (Optional) Register `Work GitLab SSH`

If the GitLab is reachable from this Mac, do this too. If it's behind corp VPN (typical), skip and handle it on day 1 of the work Mac instead.

```bash
op item get 'Work GitLab SSH' --vault='Work' --fields 'public key' | pbcopy
```

Browser → your GitLab → top-right avatar → Edit profile → SSH Keys → paste → title "Work Mac via 1Password" → Usage type **Authentication & Signing** → Add key.

### 5. Run the verifier

```bash
cd ~/Dev/dotfiles
OP_VAULT=Work     scripts/verify-op-paths.sh   # should OK both Work GitHub + Work GitLab
OP_VAULT=Personal scripts/verify-op-paths.sh   # should OK Personal GitHub + OpenAI
```

The verifier passes as long as the items **exist** in 1Password — it doesn't check whether the pubkeys are registered anywhere. You can get full green even if step 4 was skipped.

## On the work Mac (day 1)

1. Sign into Apple ID, install [1Password](https://1password.com/downloads/mac), enable SSH agent + CLI integration (Settings → Developer).
2. `op signin` — the Work vault syncs down, including both SSH keys.
3. Run bootstrap:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/nasjr08/dotfiles/main/bootstrap.sh | bash
   ```
4. At the `work_gitlab_host` prompt: enter the GitLab FQDN, e.g. `gitlab.internal.etherapeutics.co.uk`.
   - If you don't know it yet, leave blank — the SSH config gates the GitLab block behind a populated value, so blank is a clean no-op. Fill in later via `chezmoi edit-config` then `chezmoi apply`.
5. After bootstrap finishes, connect to corp VPN.
6. Register the GitLab key (if you skipped step 4 from the source-Mac flow):
   ```bash
   op item get 'Work GitLab SSH' --vault='Work' --fields 'public key' | pbcopy
   # paste into GitLab → user avatar → Edit profile → SSH Keys
   ssh -T git@gitlab.internal.etherapeutics.co.uk
   ```
   Touch ID prompt → `Welcome to GitLab, @<your-username>!`

## Reference: what "FQDN" means

Fully Qualified Domain Name — the complete hostname, all parts included. `gitlab.internal.etherapeutics.co.uk` is an FQDN; just `gitlab` or `internal.etherapeutics.co.uk` is not. At the chezmoi prompt, paste the whole thing with no `https://`, no path, no port.

## Troubleshooting

### Symptom: `git@github.com: Permission denied (publickey).`

You're running a `git clone` or `chezmoi update` over SSH and GitHub rejects you. Most common cause: 1Password's SSH agent is running but isn't whitelisted to serve any keys, so no key is offered.

Diagnose:
```bash
ssh-add -l   # if "The agent has no identities", that's your problem
```

Fix (manual, do this if chezmoi hasn't run yet):
1. In 1Password desktop → open the relevant SSH-Key item (e.g., `Work GitHub SSH`).
2. Click **Open SSH Agent Config File…** in the purple banner at the top of the item.
3. A `[[ssh-keys]]` block for that item is appended to `~/.config/1Password/ssh/agent.toml`. Save.
4. Repeat for every SSH key you want the agent to serve (e.g., also `Work GitLab SSH`).
5. **Restart the 1Password app** so the agent re-reads the file.
6. Re-run `ssh-add -l` — the keys should now appear, and `ssh -T git@github.com` should succeed.

Fix (after chezmoi has been applied at least once): `chezmoi apply` overwrites `agent.toml` from `dot_config/1Password/ssh/agent.toml.tmpl`. If you've edited the template recently (e.g., to add a new key item), just `chezmoi apply` and restart 1Password.

### Symptom: `bootstrap.sh` failing with SSH-related errors on a fresh Mac

Since the move to HTTPS for the initial clone (see `bootstrap.sh`), bootstrap itself shouldn't need SSH at all — chezmoi clones the public repo over HTTPS. If you're still hitting SSH errors during bootstrap, you've likely overridden `DOTFILES_REPO` with an SSH URL. Unset it or use the default.

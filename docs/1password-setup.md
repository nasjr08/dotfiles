# 1Password vault setup (one-time, per flavor)

Required **before** running `bootstrap.sh` on a new Mac for the first time.

## Prerequisites

- 1Password desktop app installed and signed in.
- 1Password Settings → Developer → both **Use the SSH agent** and **Integrate with 1Password CLI** enabled.
- `op` CLI installed: `brew install 1password-cli`.
- Signed in: `op signin` (you'll need it once per machine).

## What to set up for the initial bootstrap

The minimum required to bootstrap a new work Mac is the **GitHub SSH key**. Everything else can be added later as you adopt more work tooling.

### 1. Create the vault

Open the 1Password desktop app → vault dropdown → New Vault.
- For the work Mac: name it exactly `Work`.
- For the personal Mac: the default `Personal` vault is fine.

### 2. Generate the GitHub SSH key inside 1Password

In the 1Password app:

1. New item → SSH Key.
2. Title: `Work GitHub SSH` (for the work vault) or `Personal GitHub SSH` (for the personal vault). The exact title matters — `scripts/verify-op-paths.sh` looks for `<VaultName> GitHub SSH`.
3. Vault: select the vault from step 1.
4. Click **Add Private Key** → **Generate** → **Ed25519**.
5. Save.

Then on the source Mac:

```bash
op item get 'Work GitHub SSH' --vault='Work' --fields 'public key' | pbcopy
```

Paste the public key into GitHub → Settings → SSH and GPG keys → New SSH key. Title it something like "Work Mac via 1Password".

Test the SSH agent is serving it:

```bash
ssh -T git@github.com
```

You should see a Touch ID prompt; on success: `Hi <github-username>! You've successfully authenticated...`.

### 3. Verify

```bash
~/Dev/dotfiles/scripts/verify-op-paths.sh
```

Expected: `All paths OK.` If FAIL: check the item name/vault in 1Password matches what the script expects.

---

## Extending later: AWS credentials

When you need `aws` CLI on the work Mac, add an AWS credential item:

1. In 1Password: New item → API Credential.
2. Title: `Work AWS – default` (the suffix `default` matches the AWS profile name).
3. Vault: `Work`.
4. Custom fields:
    - `access_key` — text — your `aws_access_key_id`.
    - `secret_key` — password — your `aws_secret_access_key`.
5. Save.

Then uncomment the AWS lines in `scripts/verify-op-paths.sh` and re-run it.

## Extending later: API keys (OpenAI, Anthropic, etc.)

For any service consumed via env var:

1. In 1Password: New item → API Credential.
2. Title: the service name (e.g., `OpenAI`, `Anthropic`).
3. Vault: per flavor.
4. The standard `credential` field holds the API key.

Reference in chezmoi templates as:

```gotmpl
export OPENAI_API_KEY="$(op read 'op://{{ .op_vault }}/OpenAI/credential' --cache 2>/dev/null)"
```

Add a corresponding line to `scripts/verify-op-paths.sh`'s `PATHS` array.

## Reference: naming conventions

| What | Item title pattern | Field |
|---|---|---|
| GitHub SSH key | `<Vault> GitHub SSH` | `public key` (auto-populated by 1Password) |
| AWS credentials | `<Vault> AWS – <profile>` | custom: `access_key`, `secret_key` |
| Generic API key | `<ServiceName>` | `credential` (default for API Credential items) |

Keeping the patterns consistent means new items just need to be added to the verify script's `PATHS` array — no template rewrites required.

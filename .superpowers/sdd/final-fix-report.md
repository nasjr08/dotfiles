# Final Review Findings — Fix Report

Date: 2026-06-25

## Fix A — Remove `--no-lock` from `brew bundle` invocations

**File:** `.chezmoiscripts/run_onchange_20-install-brews.sh.tmpl`

**Change:** Removed `--no-lock` from all three `brew bundle` invocations.

```diff
-brew bundle --no-lock --file="$SRC/packages/Brewfile"
+brew bundle --file="$SRC/packages/Brewfile"
-brew bundle --no-lock --file="$TMP_BREWFILE_PERSONAL"
+brew bundle --file="$TMP_BREWFILE_PERSONAL"
-brew bundle --no-lock --file="$TMP_BREWFILE_WORK"
+brew bundle --file="$TMP_BREWFILE_WORK"
```

**Test result:** `chezmoi execute-template` render of the script contains no `--no-lock`; shellcheck passes under both flavors. Result: `OK: no --no-lock`

---

## Fix B — Gate Personal-vault path probe in `verify-op-paths.sh`

**File:** `scripts/verify-op-paths.sh`

**Change:** The loop now only iterates `PATHS[]` unconditionally; `PERSONAL_PATHS[]` is only probed inside `if [[ "$VAULT" == "Personal" ]]`. Also corrected the misleading comment.

```diff
-for path in "${PATHS[@]}" "${PERSONAL_PATHS[@]}"; do
+for path in "${PATHS[@]}"; do
     ...
 done
+
+if [[ "$VAULT" == "Personal" ]]; then
+    for path in "${PERSONAL_PATHS[@]}"; do
+        ...
+    done
+fi
```

**Test result:** `shellcheck: CLEAN`. With `OP_VAULT=Work` only the Work vault SSH path is probed; with `OP_VAULT=Personal` Personal paths are also probed.

---

## Fix C — Add `<GH_USER>` substitution guard to `bootstrap.sh`

**File:** `bootstrap.sh`

**Change:** Added early guard at start of `main()` that exits 1 with a clear error if `DOTFILES_REPO` still contains the literal `<GH_USER>` token.

```diff
 main() {
     : > "$LOG"
+
+    # Guard: catch un-substituted repo URL (Step 12.6 of the setup plan).
+    if [[ "$DOTFILES_REPO" == *"<GH_USER>"* ]]; then
+        echo "[bootstrap] ERROR: DOTFILES_REPO still contains the literal token <GH_USER>." >&2
+        echo "[bootstrap]   You must substitute your GitHub username before running this script." >&2
+        echo "[bootstrap]   See plan Step 12.6: sed -i '' 's/<GH_USER>/YOUR_USERNAME/g' bootstrap.sh" >&2
+        exit 1
+    fi
+
     log "starting bootstrap on ..."
```

**Test result:** `shellcheck: CLEAN`, `bash -n: CLEAN`. Manual simulation confirmed guard fires with the default un-substituted repo URL.

---

## Fix D — Add `work_org` as a 5th `promptStringOnce` + template guard

**Files:**
- `.chezmoi.toml.tmpl`
- `dot_gitconfig.tmpl`

**Changes:**

`.chezmoi.toml.tmpl`:
```diff
 {{- $opVault  := promptStringOnce . "op_vault" "1Password vault name for this flavor" (...) -}}
+{{- $workOrg  := promptStringOnce . "work_org" "Work GitHub org name (leave blank if personal)" "" -}}
 
 [data]
     ...
     op_vault = {{ $opVault | quote }}
+    work_org = {{ $workOrg | quote }}
```

`dot_gitconfig.tmpl`:
```diff
-{{ if eq .flavor "work" -}}
-# ... Replace <WORK_ORG> with the actual work GitHub org name once known.
-[url "git@github.com-work:<WORK_ORG>/"]
-    insteadOf = git@github.com:<WORK_ORG>/
+{{ if and (eq .flavor "work") .work_org -}}
+# Rewrites for the work GitHub org so SSH uses the work-specific host alias
+[url "git@github.com-work:{{ .work_org }}/"]
+    insteadOf = git@github.com:{{ .work_org }}/
 {{- end }}
```

**Test result:** With `--override-data '{"work_org":"acme","flavor":"work",...}'` the URL block appears correctly. With `work_org=""` the URL block is absent. No literal `<WORK_ORG>` remains in source.

---

## Fix E — Rename `caffeinate` alias and fix `decaf`

**Files:**
- `dot_zshrc.tmpl`
- `dot_claude/commands/decaf.md`

**Changes:**

`dot_zshrc.tmpl`:
```diff
-alias caffeinate='caffeinate -d &'
-alias decaf='pgrep caffeinate | xargs kill'
+alias caff='caffeinate -d &'
+alias decaf='pkill caffeinate'
```

`dot_claude/commands/decaf.md`: Updated to say `pkill caffeinate` instead of `pgrep | kill`.

`dot_claude/commands/caffeinate.md`: No change needed — already invokes the binary directly.

**Test result:** Rendered zshrc shows `alias caff='caffeinate -d &'` and `alias decaf='pkill caffeinate'`. Shellcheck passes.

---

## Fix F — Add 1Password SSH agent precheck to `bootstrap.sh`

**File:** `bootstrap.sh`

**Change:** Added SSH auth precheck between step 5 (backups) and step 6 (chezmoi init). Placed after chezmoi/op are installed (step 3) and after 1Password CLI signin (step 4).

```diff
     # 5. Back up anything chezmoi might overwrite
     ...
 
+    # 5b. Verify GitHub SSH auth (requires 1Password SSH agent to be configured)
+    log "checking GitHub SSH auth (requires 1Password SSH agent)"
+    if ! ssh -T -o BatchMode=yes -o ConnectTimeout=5 git@github.com 2>&1 | grep -q "successfully authenticated"; then
+        echo "[bootstrap] ERROR: GitHub SSH auth not configured." >&2
+        echo "[bootstrap]   Open 1Password → Settings → Developer → enable 'Use the SSH agent'." >&2
+        echo "[bootstrap]   See README prereqs for the full list." >&2
+        exit 1
+    fi
+
     # 6. chezmoi init + apply
```

**Test result:** `shellcheck: CLEAN`, `bash -n: CLEAN`.

---

## Fix G — Drop `--describe` from `brew bundle dump` in `capture.sh`

**File:** `scripts/capture.sh`

**Change:**
```diff
-brew bundle dump --describe --file=/tmp/Brewfile.full --force
+brew bundle dump --file=/tmp/Brewfile.full --force
```

**Test result:** `grep -- '--describe'` returns no match (OK). `shellcheck: CLEAN`.

---

## Final Commit

See git log for SHA.

Message: `fix: address final review findings — remove --no-lock, gate verify-op-paths, prompt for work_org, fix caffeinate alias, harden bootstrap`

---

## Additional Observations

1. The `--init` flag with `--promptString` on `chezmoi execute-template` for non-config templates reads from the existing `~/.config/chezmoi/chezmoi.toml` (not from the promptStrings). The test command in the brief (Test 5) using `--promptString work_org=acme` for rendering `dot_gitconfig.tmpl` does not work as written — use `--override-data` instead. The template gating itself is correct.

2. The existing chezmoi config (`~/.config/chezmoi/chezmoi.toml`) on the source Mac does not yet have a `work_org` key (this is personal flavor). The new `work_org` prompt has a default of `""` so it will not break `chezmoi apply` on the existing personal Mac — `promptStringOnce` will persist the empty string and the gitconfig URL block will be correctly absent.

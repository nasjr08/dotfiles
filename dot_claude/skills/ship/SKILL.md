---
name: ship
description: Ships the current work by committing all staged/unstaged changes, pushing to the current branch or worktree, merging to main (or opening a PR if permissions require it), tagging the release, and pushing tags. Trigger this skill whenever the user says /ship, "push changes", "merge to main", "tag and push", "ship this", "push and merge", or asks to commit and push the current work. Often run after /prep-release.
---

# ship

Commit, push, merge, tag — get the current work into main and out the door.

## Step 1 — Understand what's ready to ship

Run `git status` and `git log --oneline -10` to see:
- What's staged vs. unstaged
- What commits exist on the branch that haven't been merged to main yet
- The current branch name

If there are unstaged changes, stage them (`git add -A`) unless something looks like it shouldn't be committed (`.env`, secrets, large binaries). If in doubt, show the file list and ask.

## Step 2 — Commit

If there are uncommitted changes, create one or more commits. Use conventional commit format:

```
type(scope): short description

- bullet summarising key change
- another bullet if needed
```

Common types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`.

If the changes span clearly distinct concerns (e.g., a backend change + a frontend change), split into separate commits. But don't over-split — one clean commit per logical unit is enough.

**Never skip hooks** (`--no-verify`). If a hook fails, fix the underlying issue.

## Step 3 — Push the current branch

```bash
git push origin <current-branch>
```

If the branch has no upstream yet, set it:
```bash
git push -u origin <current-branch>
```

## Step 4 — Merge to main (or open a PR)

If the current branch is already `main`, skip to step 5.

**Try a direct merge first:**
```bash
git checkout main
git pull origin main
git merge --no-ff <branch> -m "Merge branch '<branch>' — <one-line summary> (vX.Y.Z)"
git push origin main
```

If the merge fails due to conflicts, resolve them, then continue.

**If direct push to main is rejected** (protected branch / insufficient permissions), open a PR instead:
```bash
gh pr create \
  --title "feat: <summary> (vX.Y.Z)" \
  --body "$(cat <<'EOF'
## Summary
- <bullet 1>
- <bullet 2>

## Test plan
- [ ] Smoke-tested locally
- [ ] No regressions observed

🤖 Generated with Claude Code
EOF
)"
```

Return the PR URL and let the user know they'll need to merge it manually before tagging.

## Step 5 — Tag the release on main

Make sure you're on main and it's up to date before tagging:
```bash
git checkout main && git pull origin main
```

Create an annotated tag:
```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

The version comes from the most recent `## [X.Y.Z]` heading in `CHANGELOG.md` if it exists, otherwise from whatever version source was found in step 1 of `prep-release`.

## Step 6 — Report back

Summarise what happened:
- Branch pushed ✓
- Merged to main ✓ (or: PR opened at <url>)
- Tagged vX.Y.Z ✓
- Tag pushed ✓

If anything was skipped or requires follow-up (e.g., a PR needs manual merge before the tag is meaningful), say so clearly.

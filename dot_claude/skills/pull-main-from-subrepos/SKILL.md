---
name: pull-main-from-subrepos
description: Pull main branch updates across every git repository nested under a given directory, preserving each repo's current branch. Trigger this skill when the user says "pull main everywhere", "update all repos", "fetch main across subrepos", or wants to sync a workspace containing multiple sibling git checkouts.
---

# pull-main-from-subrepos

Walk every immediate-child directory of the target path, pull main for any that are git repos, and restore each repo's pre-existing branch state.

## Step 1 — Pick the target directory

If the user passed a path argument, use it. Otherwise use `$PWD`. Confirm the chosen path with a short note before starting (e.g. `Updating repos under /Users/x/Dev/work`).

## Step 2 — Iterate

For each immediate subdirectory that contains a `.git` folder (or is a git worktree):

1. Note the current branch: `git -C <repo> rev-parse --abbrev-ref HEAD`.
2. Check for uncommitted changes: `git -C <repo> status --porcelain`. If non-empty, **skip** the repo and warn — never auto-stash someone's work.
3. If already on main: `git -C <repo> pull --ff-only origin main`.
4. If on a non-main branch:
    - `git -C <repo> fetch origin main`
    - `git -C <repo> checkout main`
    - `git -C <repo> pull --ff-only origin main`
    - `git -C <repo> checkout <original-branch>`
5. Capture the count of commits pulled (or note "already up to date").

## Step 3 — Summary

Print one line per repo:

```
<repo-name>: <N commits pulled> (now on: <branch-name>)
```

Plus a tail line: any repos skipped due to dirty state, with the file count, so the user can decide what to do.

## Notes

- Use `--ff-only` to avoid creating merge commits silently.
- The default `main` branch assumption can be overridden — if the user says "pull develop instead", substitute their branch name. Otherwise default to `main`.
- Don't recurse — only operate one level deep. The user controls the parent dir.

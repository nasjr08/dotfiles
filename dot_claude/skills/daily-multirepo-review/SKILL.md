---
name: daily-multirepo-review
description: Review the latest code changes across every git repository nested under a given directory, flag concerns, and summarise progress + next steps. Trigger when the user says "daily review", "what changed today", "review all repos", or wants a multi-repo standup-style summary.
---

# daily-multirepo-review

Walk every git repo one level under the target directory and produce a consolidated review of what's changed since the last review (or yesterday).

## Step 1 — Pick the target directory

If the user gave a path argument, use it; otherwise `$PWD`. Confirm before starting (e.g. `Reviewing repos under /Users/x/Dev/work`).

## Step 2 — Per repo

For each immediate subdirectory containing `.git`:

1. **Range to review:** use `git log --since='yesterday' --oneline` (or `--since='last review'` if a marker is tracked). If the user specifies a different range ("since Monday", "last week"), honour it.
2. **Summarise the changes:** what was added, changed, removed. Keep it short — bullets, not paragraphs.
3. **Flag concerns:**
    - **Internal to the repo:** bugs, quality issues, missing tests, broken patterns, TODOs introduced.
    - **Cross-repo:** duplicated work between sibling repos, logic that belongs in another repo, interface mismatches, version drift between consumers and producers.
4. **No changes?** Say so and note when changes were last made (`git log -1 --format='%cr'`).

Useful commands:

```bash
git -C <repo> log --since='yesterday' --oneline
git -C <repo> diff --stat <since-sha>..HEAD
git -C <repo> diff <range>          # for specific files when concerns warrant a closer look
```

## Step 3 — Close

Two final sections, in this order:

- **Summary** — short consolidated overview of what changed across all repos today (or in the chosen range).
- **Next Steps** — planned or expected work based on the current state and trajectory across repos.

## Notes

- Don't recurse — only operate one level deep.
- Skip repos with no commits in the range (mention them briefly in Summary as "no activity").
- If a repo has uncommitted local changes, mention them in its review block — they may be in-progress work worth flagging.

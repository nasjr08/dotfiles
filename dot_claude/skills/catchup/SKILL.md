---
name: catchup
description: Summarises what's recently changed in a codebase/project and suggests next steps — recent commits, changelog entries, open work, and a "where to pick up" summary. Trigger this skill whenever the user opens a project and asks things like "what's new here", "catch me up", "what changed recently", "where did I leave off", "what's the status of this project", or asks for a summary of recent work and suggested next steps. Also trigger proactively at the start of a session if the user seems to be reorienting themselves in an unfamiliar or long-untouched codebase.
---

# catchup

Get the user oriented in a project they're returning to: what changed recently, what state things are in, and what to do next.

## Step 1 — Gather recent history

Run these to build a picture of recent activity:

```bash
git log --oneline -20
git log -1 --format="%cd" --date=relative
git status
git branch --show-current
git diff --stat HEAD~5 2>/dev/null
```

If there's a `CHANGELOG.md`, read the top 1-2 release sections — these are usually a curated, human-written summary and more reliable than raw commits.

If there's a `HANDOFF.md` or similar handoff/status doc, read it — it often contains a "current state" or "next steps" section written by a previous session.

## Step 2 — Check for open/in-progress work

Look for signals of unfinished work:
- Uncommitted changes (`git status` / `git diff`) — what's being worked on right now
- TODO/FIXME comments touched recently: `git log -p -3 | grep -B2 -A2 -i "TODO\|FIXME"` (lightweight, don't grep the whole repo)
- Open branches other than main: `git branch -a`
- If a task tracker is referenced in the handoff doc or README (Linear, GitHub Issues, etc.) and the relevant MCP is connected, check for open items assigned to the user — but don't go fishing across unrelated tools if nothing points there.

## Step 3 — Summarise

Present a concise, scannable summary — not a wall of text. Structure:

```
## Recent activity
- [date/relative time of last commit, current branch]
- [2-4 bullets summarising what's changed recently — pull from changelog/commits, group related work]

## Current state
- [uncommitted changes, if any — what's mid-flight]
- [anything that looks broken/incomplete, e.g. failing tests mentioned in handoff, half-finished migration]

## Suggested next steps
- [1-3 concrete suggestions — could be: finish the in-progress work, address something flagged in the handoff doc, or a logical next feature given the trajectory of recent commits]
```

Keep it tight. The goal is "remind me where I was and what to do next," not a full project audit. If the repo is large and history is long, focus on the last week or two of activity rather than the entire log.

If nothing is in progress and no handoff doc exists, say so plainly and just summarise recent commits — don't invent next steps that aren't grounded in something you observed.

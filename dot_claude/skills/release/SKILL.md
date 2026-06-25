---
name: release
description: Full end-to-end release for any project — bumps versions, updates CHANGELOG.md and a handoff file if present, commits, pushes, merges to main, tags, and pushes tags. Trigger this skill whenever the user says /release, "do a full release", "release this", "ship a new version", "do everything for the release", or wants the complete prep + ship flow in one command. Accepts a bump type (major/minor/patch) or explicit version as an argument.
---

# release

Run the complete release flow in one shot: prep everything, then ship it.

This skill is a convenience wrapper. It runs `/prep-release` followed by `/ship` in sequence.

## How to run it

1. **Run prep-release** — follow all steps in the `prep-release` skill:
   - Determine the new version (ask if not provided)
   - Run `bump_version.py` if present, otherwise update versioned files manually
   - Update `CHANGELOG.md` with a new release section (if it exists)
   - Update handoff file if one exists

2. **Pause for review** — after prep is done, show the user a brief summary of what changed (which files, what version). Give them a moment to review before proceeding. Say something like:

   > Prep complete. Here's what changed: [summary]. Proceeding to ship in 5 seconds — say "stop" to review first.

   If they say stop, wait for their go-ahead before continuing.

3. **Run ship** — follow all steps in the `ship` skill:
   - Stage and commit all changes (including the version bump and changelog)
   - Push the current branch
   - Merge to main or open a PR
   - Tag and push the tag

## Notes

- If anything goes wrong mid-flow (merge conflict, hook failure, etc.), stop and report clearly. Don't try to power through silently.
- If the branch is already main, the merge step is skipped automatically.
- The tag is always applied to main after merge, not to the feature branch.

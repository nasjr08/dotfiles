---
name: prep-release
description: Prepares a release by bumping version numbers across the project, updating CHANGELOG.md, and updating a handoff file if one exists. Works in any project. Trigger this skill whenever the user says /prep-release, "bump version", "prepare release", "update changelog", "prep a release", or asks to update version numbers across the project. Accepts a bump type (major/minor/patch) or an explicit version number as an argument.
---

# prep-release

Prepare the project for a new release: bump the version, update the changelog, and refresh the handoff doc.

## Step 1 — Determine the current version

Look for the current version in order of preference:
1. The most recent `## [X.Y.Z]` heading in `CHANGELOG.md`
2. A `Current version:` or `version =` line in `HANDOFF.md`
3. The `"version"` field in `package.json` or `pyproject.toml`
4. A `VERSION` file, `version.py`, or `__version__` in `__init__.py`

Use whatever you find. If multiple sources exist, confirm they agree — if they don't, flag it and ask which is authoritative.

If the user passed a bump type (`major` / `minor` / `patch`) or an explicit version, use that. If they didn't specify, ask: "What kind of bump — major, minor, or patch?"

Compute the new version using semver rules (MAJOR.MINOR.PATCH).

## Step 2 — Check for bump_version.py

Look for a `bump_version.py` script at the project root. If it exists, run it with the new version — it knows which files to update. Skip step 3 and go straight to step 4.

```bash
python bump_version.py <new-version>
```

## Step 3 — Update versioned files (only if no bump_version.py)

Discover which files carry a version string by searching the repo:

```bash
grep -rl '"version"' . --include="*.json" | grep -v node_modules | grep -v .venv
grep -rl '^version' . --include="*.toml" --include="*.cfg" | grep -v node_modules | grep -v .venv
find . \( -name "version.py" -o -name "VERSION" \) | grep -v node_modules | grep -v .venv
grep -rl '__version__' . --include="*.py" | grep -v node_modules | grep -v .venv
```

Update each file found. Common patterns:
| File type | Pattern to update |
|-----------|-------------------|
| `package.json` / `manifest.json` | `"version": "X.Y.Z"` |
| `pyproject.toml` | `version = "X.Y.Z"` |
| `version.py` / `__init__.py` | `__version__ = "X.Y.Z"` |
| `VERSION` | Plain version string |

Also update any "last updated" or date field alongside the version if present.

## Step 4 — Update CHANGELOG.md (if it exists)

If `CHANGELOG.md` exists, follow [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.

1. Look at recent git commits since the last tag: `git log $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --oneline`
2. Insert a new section **at the top** (below the header block, above the previous release):

```
## [X.Y.Z] — YYYY-MM-DD

### Added
- ...

### Changed
- ...

### Fixed
- ...
```

Only include subsections that have entries. Be descriptive — group related items logically.

## Step 5 — Update handoff file (if it exists)

Look for `HANDOFF.md`, `HANDOFF.txt`, or a similarly named file at the project root. If found, surgically update:
- Version reference → new version
- Last updated date → today (YYYY-MM-DD)
- Current branch → run `git branch --show-current`
- Any "recent changes" or "what's new" section — summarise the release in 2–3 bullets

Do **not** rewrite the whole file. Targeted edits only.

## Step 6 — Report back

List every file changed and what was updated in each. End with:

> Ready to ship. Run `/ship` (or use `/release` next time to do everything in one go).

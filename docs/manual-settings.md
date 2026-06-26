# Manual settings runbook

Settings and tweaks that **aren't** managed by chezmoi — UI-only preferences,
hotkey panels, opaque plist settings, keyboard-shortcut presets, etc. After
running bootstrap on a new Mac, walk through this list to recreate the
personalised tweaks.

> Whenever you discover a setting that has to be clicked manually, **add it
> here**. Use the template at the bottom of the file.

---

## iTerm2

### Natural Text Editing keybindings

Lets you delete words / lines / jump to start-or-end with Option+arrow,
Cmd+Backspace, etc. — the same shortcuts that work in macOS text fields.

1. **Settings → Profiles**.
2. Select your default profile (or whichever you use).
3. **Keys** tab → **Key Bindings** sub-tab.
4. Click the **Presets…** dropdown → **Natural Text Editing**.
5. Confirm replacing the existing key bindings when prompted.

### Dedicated hotkey window

A floating iTerm2 window that toggles with a global hotkey — quick terminal
without alt-tabbing.

1. **Settings → Keys → Hotkey**.
2. Click **Create a Dedicated Hotkey Window…**.
3. Set hotkey to **Ctrl + Space** (or your preference).
4. In the new profile's settings panel that appears:
   - **Floating window**: ✓
   - **Automatically reopen on app reactivation**: ✓

---

## Template for new entries

When you find a setting that has to be done by hand, paste this skeleton and
fill it in. Keep entries grouped by app (one `##` per app), with one `###` per
setting.

```markdown
## <App name>

### <Short description of what the setting does>

<One-line context: when you'd want this, why it matters.>

1. **<Menu path step 1>**
2. <Step 2>
3. <Step 3>
   - <Sub-option>: ✓
   - <Sub-option>: ✓
```

---
name: make-branch-specific-icon
description: "Generate a custom Windows taskbar icon and shortcut for a VS Code repo+branch so it appears as its own taskbar group, ungrouped from other VS Code windows. Uses AppUserModelID on the window handle. WHEN: custom taskbar icon, branch icon, separate taskbar group, VS Code icon, repo icon, ungrouped taskbar, distinguish branches in taskbar, custom VS Code shortcut."
---

# make-branch-specific-icon

Generates a custom Windows taskbar icon + launcher for the current repo (or repo+branch), so it appears as its own separate group in the Windows taskbar — ungrouped from other VS Code windows.

## When to Use

- "Make a custom icon for this repo"
- "I want this branch to have its own taskbar icon"
- "Separate this VS Code window in the taskbar"
- "Custom taskbar shortcut for this project"

## When NOT to Use

- On macOS or Linux (this uses Windows Shell APIs)
- When the user just wants to change the VS Code color theme (suggest workspace colors instead)

## Prerequisites

- Windows 10/11
- PowerShell 5.1+ or PowerShell Core 7+
- VS Code with `code` in PATH
- Must be inside a git repository

## Instructions

### Step 1 — Interview the user for icon design

Ask the user to describe what they want the icon to look like. Prompt with questions like:

- What symbol or shape? (e.g., terminal prompt `>_`, a letter, a gear, a lightning bolt, brackets `{}`)
- What color scheme? (e.g., phosphor green on dark, blue neon, orange sunset, purple cyberpunk)
- Any special effects? (e.g., glow, CRT scan lines, gradient, outline only)
- What shortcut name for the Desktop? (default: repo name)

Get enough detail to generate a distinctive icon. If the user is vague, suggest 2–3 concrete options.

### Step 2 — Determine identifiers

From the current git context, determine:

- **Repo name**: `git rev-parse --show-toplevel` → leaf name
- **Branch name** (optional): `git rev-parse --abbrev-ref HEAD` — only if the user wants branch-specific
- **AppUserModelID**: Construct as `Custom.{RepoName}.{BranchSafe}.VSCode` (e.g., `Custom.MyApp.FeatureAuth.VSCode`). Use only alphanumeric and dots. Max 128 chars.
- **Safe filename**: repo name (+ branch if applicable), with `/\` replaced by `-`

### Step 3 — Generate the setup script

Generate a single PowerShell script at `{repo}/.vscode/setup-taskbar-icon.ps1` that contains:

1. **Icon generation** using `System.Drawing` — a `New-Icon([int]$Size)` function that draws the user's requested design onto a bitmap. Use the [icon drawing reference](./references/icon-drawing-patterns.md) for techniques.
2. **Multi-size ICO writing** — sizes 256, 48, 32, 16 packed into a single `.ico` file
3. **Launcher script generation** — writes a `launch.ps1` next to the icon that starts VS Code, finds the window, and sets `AppUserModelID` + icon on the window handle. Use the [launcher template](./scripts/launcher-template.ps1) as the base.
4. **Desktop shortcut creation** — `.lnk` file targeting `pwsh -WindowStyle Hidden -File launch.ps1`, with custom icon and `AppUserModelID` set on the shortcut too
5. Output paths: icon and launcher go to `~/.agents/assets/{safe-filename}/`

### Step 4 — Important implementation details

- The setup script must be **idempotent** — safe to re-run
- The launcher must set `AppUserModelID` on the **window handle** via `SHGetPropertyStoreForWindow`, not just on the shortcut — this is what prevents grouping
- The launcher must also set the icon on the window via `WM_SETICON` (both `ICON_BIG` and `ICON_SMALL`)
- The launcher PowerShell window itself must be hidden (`-WindowStyle Hidden`)
- The shortcut `.WindowStyle` should be set to `7` (minimized) as a fallback

### Step 5 — Tell the user how to run it

After generating the script, tell the user:

```
To set up the custom taskbar icon:

1. Run:  pwsh ./.vscode/setup-taskbar-icon.ps1
2. Right-click the new shortcut on your Desktop → "Pin to taskbar"
3. Launch from the pinned icon — it will appear as its own taskbar group

To regenerate after changes:  re-run step 1.
```

### Constraints

- Do NOT commit the `.vscode/setup-taskbar-icon.ps1` to the repo — it's developer-local. Add it to `.gitignore` if not already ignored.
- Icon drawing must use only `System.Drawing` (ships with .NET / PowerShell) — no external dependencies.
- Keep the generated script self-contained — a single file that does everything.

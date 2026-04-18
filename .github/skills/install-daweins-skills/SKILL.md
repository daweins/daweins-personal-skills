---
name: install-daweins-skills
description: "Install or uninstall personal agentic skills from this repo to ~/.agents/skills/ for global availability across all VS Code workspaces. WHEN: install skills, set up new dev box, sync skills, uninstall skills, remove skills."
---

# install-daweins-skills

Copies all skills from this repo's `.github/skills/` directory into `~/.agents/skills/`, making them available in every VS Code workspace without committing to any project repo.

## When to Use

- Setting up a new development machine after cloning this repo
- Syncing updated skills after pulling new changes
- "Install my skills", "set up skills", "sync skills to this box"
- Uninstalling: "remove my skills", "uninstall skills"

## When NOT to Use

- When you want skills only in this workspace (they're already loaded here)
- For installing third-party or marketplace skills

## Prerequisites

- PowerShell 5.1+ (Windows) or PowerShell Core 7+ (macOS/Linux)
- This repo must be cloned locally

## Instructions

### Install

Run the installer script from this repo:

```powershell
./.github/skills/install-daweins-skills/scripts/install.ps1
```

The script will:
1. Find all skill folders in `.github/skills/` (excluding itself)
2. Copy each skill to `~/.agents/skills/`
3. Overwrite existing versions (safe to re-run)
4. Write a manifest (`.daweins-installed-skills.json`) for tracking

### Uninstall

To remove only the skills installed by this script:

```powershell
./.github/skills/install-daweins-skills/scripts/install.ps1 -Uninstall
```

This reads the manifest and removes only skills that were installed from this repo. Other skills in `~/.agents/skills/` are untouched.

### New machine workflow

```bash
git clone https://github.com/daweins/daweins-personal-skills.git
cd daweins-personal-skills
pwsh ./.github/skills/install-daweins-skills/scripts/install.ps1
```

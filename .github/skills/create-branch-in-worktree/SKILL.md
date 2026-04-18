---
name: create-branch-in-worktree
description: "Create a new git branch and open it in a dedicated worktree directory, organized by repo and branch name. Each branch gets its own isolated worktree folder. WHEN: new branch worktree, create branch in worktree, worktree branch, start new feature branch, new worktree, open branch in worktree."
---

# create-branch-in-worktree

Creates a new git branch and sets it up in a dedicated worktree, organized as `{worktree-root}/{repo-name}/{branch-name}`. Opens the worktree in a new VS Code window.

## When to Use

- "Create a branch in a worktree"
- "New feature branch in worktree"
- "Start working on feature-xyz in a worktree"
- Any time you want a new branch with its own isolated worktree directory

## When NOT to Use

- When you want to switch branches in-place (just use `git checkout`)
- When working with an existing worktree (use `git worktree list`)
- For managing or removing worktrees

## Prerequisites

- Git 2.15+ (worktree support)
- PowerShell 5.1+ or PowerShell Core 7+
- Must be inside a git repository

## Instructions

When triggered, run the worktree creation script:

```powershell
./.github/skills/create-branch-in-worktree/scripts/create-worktree.ps1 -BranchName "<branch-name>"
```

Or from the installed location:

```powershell
~/.agents/skills/create-branch-in-worktree/scripts/create-worktree.ps1 -BranchName "<branch-name>"
```

### What the script does

1. **Checks current branch** — if not on `main` (or `master`), confirms with the user before proceeding
2. **Pulls latest** — runs `git pull` to ensure you're up to date
3. **Loads config** — reads worktree root from `config.json` in the installed skill directory (`~/.agents/skills/create-branch-in-worktree/config.json`). If missing, prompts the user for a worktree root path and saves it
4. **Creates directory structure** — `{worktree-root}/{repo-name}/{branch-name}`
5. **Creates branch + worktree** — `git worktree add {path} -b {branch-name}`
6. **Opens in VS Code** — launches a new VS Code window at the worktree path

### Configuration

The worktree root location is stored in `~/.agents/skills/create-branch-in-worktree/config.json`:

```json
{
  "worktreeRoot": "C:\\Worktrees"
}
```

To change the worktree root, edit or delete this file. The script will re-prompt on next run if the file is missing.

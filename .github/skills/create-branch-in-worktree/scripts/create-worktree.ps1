#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a new git branch in a dedicated worktree directory.
.DESCRIPTION
    Checks you're on main, pulls latest, creates a new branch, sets up a worktree
    at {worktreeRoot}/{repoName}/{branchName}, and opens it in a new VS Code window.

    Worktree root is stored in config.json in the installed skill directory
    (~/.agents/skills/create-branch-in-worktree/config.json).
.PARAMETER BranchName
    The name of the new branch to create.
.PARAMETER WorktreeRoot
    Optional. Set a new worktree root directory. Saves to config and uses it immediately.
    Does not move existing worktrees from the old location.
.EXAMPLE
    ./create-worktree.ps1 -BranchName feature/my-feature
.EXAMPLE
    ./create-worktree.ps1 -BranchName feature/xyz -WorktreeRoot D:\Worktrees
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,

    [string]$WorktreeRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Validate git repo ---
$gitRoot = git rev-parse --show-toplevel 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Not inside a git repository. Navigate to a repo first."
    exit 1
}

# --- Check current branch ---
$currentBranch = git rev-parse --abbrev-ref HEAD
$defaultBranches = @('main', 'master')

if ($currentBranch -notin $defaultBranches) {
    Write-Host "WARNING: You are on branch '$currentBranch', not main/master." -ForegroundColor Yellow
    $confirm = Read-Host "Continue anyway? (y/N)"
    if ($confirm -notmatch '^[Yy]') {
        Write-Host "Aborted." -ForegroundColor Red
        exit 0
    }
}

# --- Pull latest ---
Write-Host "Pulling latest on '$currentBranch'..." -ForegroundColor Cyan
git pull
if ($LASTEXITCODE -ne 0) {
    Write-Error "git pull failed. Resolve any issues and try again."
    exit 1
}

# --- Load or create config ---
$configDir = Join-Path $HOME '.agents' 'skills' 'create-branch-in-worktree'
$configFile = Join-Path $configDir 'config.json'

if (Test-Path $configFile) {
    $config = Get-Content $configFile -Raw | ConvertFrom-Json
    $worktreeRoot = $config.worktreeRoot
} else {
    $worktreeRoot = $null
}

# Override with parameter if provided
if ($WorktreeRoot) {
    $worktreeRoot = $WorktreeRoot.Trim('"').Trim("'")
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    @{ worktreeRoot = $worktreeRoot } | ConvertTo-Json | Set-Content $configFile -Encoding UTF8
    Write-Host "Worktree root updated to: $worktreeRoot" -ForegroundColor Green
}

if ([string]::IsNullOrWhiteSpace($worktreeRoot)) {
    Write-Host "`nNo worktree root configured yet." -ForegroundColor Yellow
    $worktreeRoot = Read-Host "Enter the root directory for all worktrees (e.g., C:\Worktrees)"
    $worktreeRoot = $worktreeRoot.Trim('"').Trim("'")

    if ([string]::IsNullOrWhiteSpace($worktreeRoot)) {
        Write-Error "Worktree root cannot be empty."
        exit 1
    }

    # Ensure config directory exists
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    @{ worktreeRoot = $worktreeRoot } | ConvertTo-Json | Set-Content $configFile -Encoding UTF8
    Write-Host "Saved worktree root to: $configFile" -ForegroundColor Green
}

# Validate worktree root exists or create it
if (-not (Test-Path $worktreeRoot)) {
    New-Item -ItemType Directory -Path $worktreeRoot -Force | Out-Null
    Write-Host "Created worktree root: $worktreeRoot" -ForegroundColor Cyan
}

# --- Determine repo name ---
$repoName = Split-Path $gitRoot -Leaf

# --- Build worktree path ---
$worktreePath = Join-Path $worktreeRoot $repoName $BranchName

if (Test-Path $worktreePath) {
    Write-Error "Worktree directory already exists: $worktreePath"
    exit 1
}

# Ensure the repo subdirectory exists
$repoDir = Join-Path $worktreeRoot $repoName
if (-not (Test-Path $repoDir)) {
    New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
}

# --- Check if branch already exists ---
$existingBranch = git branch --list $BranchName 2>&1
$existingRemoteBranch = git branch -r --list "origin/$BranchName" 2>&1

if ($existingBranch -match $BranchName) {
    Write-Host "Branch '$BranchName' already exists locally. Creating worktree without -b flag..." -ForegroundColor Yellow
    git worktree add $worktreePath $BranchName
} elseif ($existingRemoteBranch -match $BranchName) {
    Write-Host "Branch '$BranchName' exists on remote. Tracking it..." -ForegroundColor Yellow
    git worktree add --track -b $BranchName $worktreePath "origin/$BranchName"
} else {
    Write-Host "Creating new branch '$BranchName'..." -ForegroundColor Cyan
    git worktree add -b $BranchName $worktreePath
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create worktree."
    exit 1
}

Write-Host "`nWorktree created:" -ForegroundColor Green
Write-Host "  Branch: $BranchName" -ForegroundColor Green
Write-Host "  Path:   $worktreePath" -ForegroundColor Green

# --- Open in VS Code ---
Write-Host "Opening in new VS Code window..." -ForegroundColor Cyan
code $worktreePath

Write-Host "`nDone!" -ForegroundColor Green

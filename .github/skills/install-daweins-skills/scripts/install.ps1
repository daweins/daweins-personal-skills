#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs personal agentic skills from this repo to ~/.agents/skills/
.DESCRIPTION
    Copies all skill folders from the repo's .github/skills/ directory into the user's
    personal skills directory (~/.agents/skills/), making them available in
    VS Code across all workspaces without committing to any repo.

    Safe to run multiple times (idempotent). Existing skills from other sources
    are left untouched. Skills from this repo are overwritten with the latest version.
.PARAMETER Uninstall
    Remove skills that were installed by this script (based on manifest).
.EXAMPLE
    ./install.ps1
    ./install.ps1 -Uninstall
#>
param(
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Paths ---
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$skillsSource = Join-Path (Join-Path $repoRoot '.github') 'skills'
$targetDir = Join-Path (Join-Path $HOME '.agents') 'skills'
$manifestFile = Join-Path $targetDir '.daweins-installed-skills.json'

if (-not (Test-Path $skillsSource)) {
    Write-Error "Skills source directory not found: $skillsSource"
    exit 1
}

# --- Uninstall mode ---
if ($Uninstall) {
    if (-not (Test-Path $manifestFile)) {
        Write-Host 'No install manifest found. Nothing to uninstall.' -ForegroundColor Yellow
        exit 0
    }
    $manifest = Get-Content $manifestFile -Raw | ConvertFrom-Json
    foreach ($skillName in $manifest.skills) {
        $skillPath = Join-Path $targetDir $skillName
        if (Test-Path $skillPath) {
            Remove-Item $skillPath -Recurse -Force
            Write-Host "  Removed: $skillName" -ForegroundColor Red
        }
    }
    Remove-Item $manifestFile -Force
    Write-Host "`nUninstall complete." -ForegroundColor Green
    exit 0
}

# --- Install mode ---
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Host "Created: $targetDir" -ForegroundColor Cyan
}

$installedSkills = @()
$skillFolders = Get-ChildItem $skillsSource -Directory

if ($skillFolders.Count -eq 0) {
    Write-Host 'No skills found to install.' -ForegroundColor Yellow
    exit 0
}

foreach ($skill in $skillFolders) {
    # Skip the installer skill itself — it doesn't need to be globally installed
    if ($skill.Name -eq 'install-daweins-skills') { continue }

    $dest = Join-Path $targetDir $skill.Name

    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
        $action = 'Updated'
    } else {
        $action = 'Installed'
    }

    Copy-Item $skill.FullName $dest -Recurse -Force
    $installedSkills += $skill.Name
    Write-Host "  ${action}: $($skill.Name)" -ForegroundColor Green
}

# Write manifest for clean uninstall
$manifest = @{
    source    = $repoRoot
    installed = (Get-Date -Format 'o')
    skills    = $installedSkills
}
$manifest | ConvertTo-Json -Depth 3 | Set-Content $manifestFile -Encoding UTF8

Write-Host "`n$($installedSkills.Count) skill(s) installed to $targetDir" -ForegroundColor Cyan
Write-Host "Manifest written to $manifestFile" -ForegroundColor DarkGray

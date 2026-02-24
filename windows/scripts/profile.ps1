#Requires -Version 7.0
<#
.SYNOPSIS
    Installs the PowerShell 7 profile with Starship, PSReadLine config, and aliases.
    The profile file is the runtime configuration that loads on every new pwsh session.
#>

param(
    [Parameter(Mandatory)]
    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"

function Write-Cyan    { param([string]$Text) Write-Host $Text -ForegroundColor Cyan }
function Write-Green   { param([string]$Text) Write-Host $Text -ForegroundColor Green }
function Write-Yellow  { param([string]$Text) Write-Host $Text -ForegroundColor Yellow }
function Write-Red     { param([string]$Text) Write-Host $Text -ForegroundColor Red }

Write-Cyan "── PowerShell Profile Installation ──"

$sourceProfile = Join-Path $RepoRoot "windows" "profile" "Microsoft.PowerShell_profile.ps1"
$profileDir = Split-Path -Parent $PROFILE.CurrentUserAllHosts
$destProfile = $PROFILE.CurrentUserCurrentHost  # Documents\PowerShell\Microsoft.PowerShell_profile.ps1

if (-not (Test-Path $sourceProfile)) {
    Write-Red "Profile template not found: $sourceProfile"
    exit 1
}

# Create profile directory if needed
if (-not (Test-Path $profileDir)) {
    Write-Yellow "Creating PowerShell profile directory..."
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Managed block markers
$blockStart = "# <>< terminal-customization managed start ><>"
$blockEnd   = "# <>< terminal-customization managed end ><>"

$newBlock = Get-Content $sourceProfile -Raw

# Strip ALL existing managed blocks (handles duplicates from previous runs)
# then append a single fresh block — guarantees idempotency.
$baseContent = ""
if (Test-Path $destProfile) {
    $existingContent = (Get-Content $destProfile -Raw) ?? ""

    # Remove every occurrence of the managed block (greedy, handles multiple copies)
    $pattern = "(?m)\s*" + [regex]::Escape($blockStart) + "[\s\S]*?" + [regex]::Escape($blockEnd) + "\s*"
    $baseContent = ([regex]::Replace($existingContent, $pattern, "")).TrimEnd()

    if ($existingContent -match [regex]::Escape($blockStart)) {
        Write-Yellow "Updating existing managed block in profile..."
    } else {
        Write-Yellow "Appending terminal customization to existing profile..."
    }
} else {
    Write-Yellow "Creating new PowerShell profile..."
}

# Write base content (anything outside the managed block) + fresh block
$separator = if ($baseContent) { "`n`n" } else { "" }
$finalContent = $baseContent + $separator + $blockStart + "`n" + $newBlock + "`n" + $blockEnd + "`n"
Set-Content -Path $destProfile -Value $finalContent -NoNewline
Write-Green "Profile written to: $destProfile"

# ── Copy profile-modules alongside the profile ──
$sourceModules = Join-Path $RepoRoot "windows" "profile" "profile-modules"
$destModules   = Join-Path $profileDir "profile-modules"

if (Test-Path $sourceModules) {
    if (Test-Path $destModules) {
        Remove-Item $destModules -Recurse -Force
    }
    Copy-Item -Path $sourceModules -Destination $destModules -Recurse -Force
    Write-Green "Profile modules copied to: $destModules"
} else {
    Write-Red "Profile modules directory not found: $sourceModules"
}

Write-Green "PowerShell profile installation complete."
Write-Yellow "Profile location: $destProfile"

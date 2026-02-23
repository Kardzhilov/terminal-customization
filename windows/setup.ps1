#Requires -Version 7.0
<#
.SYNOPSIS
    Main Windows terminal customization setup.
    This script runs inside PowerShell 7+ and orchestrates all sub-scripts.
.PARAMETER RepoRoot
    The root directory of the terminal-customization repository.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$LASTEXITCODE = 0

# Resolve repo root if not supplied
if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$WindowsDir = Join-Path $RepoRoot "windows"
$ScriptsDir = Join-Path $WindowsDir "scripts"

# ── Colour helpers ──
function Write-Cyan    { param([string]$Text) Write-Host $Text -ForegroundColor Cyan }
function Write-Green   { param([string]$Text) Write-Host $Text -ForegroundColor Green }
function Write-Yellow  { param([string]$Text) Write-Host $Text -ForegroundColor Yellow }
function Write-Red     { param([string]$Text) Write-Host $Text -ForegroundColor Red }
function Write-Magenta { param([string]$Text) Write-Host $Text -ForegroundColor Magenta }

function Exit-WithError {
    param([string]$Message = "Something went wrong.")
    Write-Red $Message
    exit 1
}

# ── Welcome ──
Write-Host ""
Write-Cyan "========================================="
Write-Cyan "  Windows Terminal Customization"
Write-Cyan "  Running in PowerShell $($PSVersionTable.PSVersion)"
Write-Cyan "========================================="
Write-Host ""

Write-Host "Would you like to customize your " -NoNewline
Write-Host "Terminal" -ForegroundColor Green -NoNewline
Write-Host " ?" -NoNewline
$choice = Read-Host " (Y/N)"
if ($choice -notin @('Y', 'y', 'yes')) {
    Write-Green "Have a nice day!"
    exit 0
}

# ── Step 1: Install Fonts ──
Write-Host ""
& (Join-Path $ScriptsDir "fonts.ps1") -RepoRoot $RepoRoot
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Exit-WithError "Font installation failed." }

# ── Step 2: Install & Configure Starship ──
Write-Host ""
& (Join-Path $ScriptsDir "starship.ps1") -RepoRoot $RepoRoot
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Exit-WithError "Starship setup failed." }

# ── Step 3: Configure PSReadLine ──
Write-Host ""
& (Join-Path $ScriptsDir "psreadline.ps1") -RepoRoot $RepoRoot
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Exit-WithError "PSReadLine configuration failed." }

# ── Step 4: Install Profile & Aliases ──
Write-Host ""
& (Join-Path $ScriptsDir "profile.ps1") -RepoRoot $RepoRoot
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Exit-WithError "Profile installation failed." }

# ── Done ──
Write-Host ""
Write-Cyan "========================================="
Write-Green "  Customization Complete!"
Write-Cyan "========================================="
Write-Host ""
Write-Yellow "Remember to:"
Write-Yellow "  1. Set your Windows Terminal font to 'MesloLGS NF' in Settings > Profiles > Defaults > Appearance"
Write-Yellow "  2. Import the Gruvbox colour scheme from theme/windows-terminal-colours.json"
Write-Yellow "  3. Restart your terminal to see all changes"
Write-Host ""
Write-Cyan "Open a new PowerShell 7 (pwsh) window to start using your customized terminal!"

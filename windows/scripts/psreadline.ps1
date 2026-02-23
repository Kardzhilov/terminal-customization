#Requires -Version 7.0
<#
.SYNOPSIS
    Configures PSReadLine to provide zsh-like autosuggestions and syntax highlighting.
    PSReadLine ships with PowerShell 7+ — no extra installation needed.
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

Write-Cyan "── PSReadLine Configuration ──"

# ── Ensure PSReadLine is available and up-to-date ──
$psrlModule = Get-Module -ListAvailable -Name PSReadLine | Sort-Object Version -Descending | Select-Object -First 1

if (-not $psrlModule) {
    Write-Yellow "PSReadLine module not found. Installing..."
    Install-Module -Name PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser
} else {
    Write-Green "PSReadLine $($psrlModule.Version) is available."

    # Update if older than 2.3 (needed for PredictionSource HistoryAndPlugin, ListView, etc.)
    if ($psrlModule.Version -lt [Version]"2.3.0") {
        Write-Yellow "Updating PSReadLine to latest version for full feature support..."
        Install-Module -Name PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser -AllowPrerelease:$false
    }
}

Write-Green "PSReadLine will be configured in your PowerShell profile."
Write-Green "Features enabled:"
Write-Green "  - History-based autosuggestions (like zsh-autosuggestions)"
Write-Green "  - Syntax highlighting with Gruvbox-inspired colours (like zsh-syntax-highlighting)"
Write-Green "  - ListView prediction view for interactive completions"
Write-Green "  - Ctrl+Right/Left for word-by-word navigation"
Write-Green "  - Ctrl+d to exit (like Unix shells)"

Write-Green "PSReadLine configuration ready."

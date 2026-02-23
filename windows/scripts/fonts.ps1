#Requires -Version 7.0
<#
.SYNOPSIS
    Installs the MesloLGS NF fonts from the repo's fonts/ directory.
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

Write-Cyan "── Font Installation ──"

$fontsSourceDir = Join-Path $RepoRoot "fonts"
$fontsDestDir = "$env:WINDIR\Fonts"
$fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

if (-not (Test-Path $fontsSourceDir)) {
    Write-Red "Fonts directory not found at: $fontsSourceDir"
    exit 1
}

$fontFiles = Get-ChildItem -Path $fontsSourceDir -Filter "*.ttf"

if ($fontFiles.Count -eq 0) {
    Write-Yellow "No .ttf font files found in fonts/ directory."
    exit 0
}

$installedCount = 0
$skippedCount = 0

foreach ($font in $fontFiles) {
    $destPath = Join-Path $fontsDestDir $font.Name

    if (Test-Path $destPath) {
        Write-Green "  Already installed: $($font.Name)"
        $skippedCount++
        continue
    }

    try {
        # Copy font file to Windows Fonts directory
        Copy-Item -Path $font.FullName -Destination $destPath -Force

        # Register the font in the registry
        # Derive a friendly name from the filename (strip .ttf extension)
        $fontName = [System.IO.Path]::GetFileNameWithoutExtension($font.Name) + " (TrueType)"
        Set-ItemProperty -Path $fontRegistryPath -Name $fontName -Value $font.Name

        Write-Green "  Installed: $($font.Name)"
        $installedCount++
    } catch {
        Write-Red "  Failed to install: $($font.Name) - $($_.Exception.Message)"
    }
}

Write-Host ""
if ($installedCount -gt 0) {
    Write-Green "$installedCount font(s) installed, $skippedCount already present."
    Write-Yellow "Note: You may need to restart applications to see the new fonts."
} else {
    Write-Green "All fonts were already installed."
}

Write-Yellow "Remember to set your terminal font to 'MesloLGS NF' in Windows Terminal settings."

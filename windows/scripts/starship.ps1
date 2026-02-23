#Requires -Version 7.0
<#
.SYNOPSIS
    Installs Starship prompt and configures it with the gruvbox-rainbow preset.
    Uses the same theme as the Linux version of this repo.
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
function Write-Magenta { param([string]$Text) Write-Host $Text -ForegroundColor Magenta }

Write-Cyan "── Starship Prompt Setup ──"

Write-Host "Would you like to install and configure " -NoNewline
Write-Host "Starship" -ForegroundColor Magenta -NoNewline
Write-Host " shell prompt?" -NoNewline
$choice = Read-Host " (Y/N)"
if ($choice -notin @('Y', 'y', 'yes')) {
    Write-Green "Skipping Starship installation."
    exit 0
}

# ── Install Starship via winget ──
$starshipInstalled = $false
try {
    $null = Get-Command starship -ErrorAction Stop
    $starshipInstalled = $true
} catch {
    $starshipInstalled = $false
}

if (-not $starshipInstalled) {
    Write-Yellow "Installing Starship via winget..."
    winget install --id Starship.Starship --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Red "winget install failed. Trying direct installer..."
        # Fallback: use the official install script
        $installerUrl = "https://starship.rs/install.sh"
        Write-Yellow "Attempting install via official installer..."
        try {
            # Use the Windows MSI installer from GitHub
            $releaseApiUrl = "https://api.github.com/repos/starship/starship/releases/latest"
            $release = Invoke-RestMethod -Uri $releaseApiUrl -UseBasicParsing
            $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
            $asset = $release.assets | Where-Object { $_.name -match "win-$arch\.msi$" } | Select-Object -First 1
            if ($asset) {
                $msiPath = Join-Path $env:TEMP "starship-installer.msi"
                Write-Yellow "Downloading Starship MSI..."
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $msiPath -UseBasicParsing
                Write-Yellow "Installing Starship MSI..."
                Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn" -Wait -NoNewWindow
                Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
            } else {
                throw "Could not find Starship MSI in latest release."
            }
        } catch {
            Write-Red "Failed to install Starship: $($_.Exception.Message)"
            Write-Yellow "Please install Starship manually: https://starship.rs"
            exit 1
        }
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Verify installation
try {
    $starshipVersion = & starship --version 2>&1 | Select-Object -First 1
    Write-Green "Starship installed: $starshipVersion"
} catch {
    Write-Red "Starship is not available after installation."
    Write-Yellow "You may need to restart your terminal and re-run this script."
    exit 1
}

# ── Configure Starship ──
$configDir = Join-Path $env:USERPROFILE ".config"
$configFile = Join-Path $configDir "starship.toml"

if (-not (Test-Path $configDir)) {
    Write-Yellow "Creating ~/.config/ directory..."
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

if (-not (Test-Path $configFile)) {
    Write-Yellow "Generating Starship gruvbox-rainbow preset..."
    & starship preset gruvbox-rainbow -o $configFile
    Write-Green "Starship configuration written to: $configFile"
} else {
    Write-Green "Starship configuration already exists at: $configFile"
}

# ── Disable time module (matching Linux config) ──
if (Test-Path $configFile) {
    $content = Get-Content $configFile -Raw

    # Check if [time] section exists with disabled = false, and flip it to true
    if ($content -match '\[time\]' -and $content -match 'disabled\s*=\s*false') {
        Write-Yellow "Disabling time module in Starship configuration..."
        $content = $content -replace '((?<=\[time\][\s\S]*?))disabled\s*=\s*false', '$1disabled = true'
        Set-Content -Path $configFile -Value $content -NoNewline
        Write-Green "Time module disabled."
    } else {
        Write-Green "Time module already disabled or not present."
    }
}

Write-Green "Starship setup complete."

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
    # Reset sources first to mitigate common source index corruption (0x8a15000f)
    winget source reset --force 2>&1 | Out-Null
    winget install --id Starship.Starship --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Yellow "winget install failed. Retrying after source reset..."
        winget source reset --force 2>&1 | Out-Null
        winget install --id Starship.Starship --source winget --accept-source-agreements --accept-package-agreements
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Red "winget install failed. Trying direct installer..."
        Write-Yellow "Attempting install via GitHub release asset..."
        try {
            # Download the architecture-specific Windows ZIP and install starship.exe.
            $releaseApiUrl = "https://api.github.com/repos/starship/starship/releases/latest"
            $release = Invoke-RestMethod -Uri $releaseApiUrl -UseBasicParsing -ErrorAction Stop
            $targetArch = if ([Environment]::Is64BitOperatingSystem) {
                if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'aarch64' } else { 'x86_64' }
            } else {
                'i686'
            }

            $assetPattern = "^starship-$targetArch-pc-windows-msvc\.zip$"
            $asset = $release.assets | Where-Object { $_.name -match $assetPattern } | Select-Object -First 1
            if ($asset) {
                $zipPath = Join-Path $env:TEMP "starship-$targetArch.zip"
                $extractDir = Join-Path $env:TEMP "starship-$targetArch"
                $installDir = Join-Path $env:ProgramFiles "starship\bin"
                $installExe = Join-Path $installDir "starship.exe"

                Write-Yellow "Downloading $($asset.name)..."
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop

                if (Test-Path $extractDir) {
                    Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue
                }
                Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

                $downloadedExe = Get-ChildItem -Path $extractDir -Filter "starship.exe" -Recurse -ErrorAction Stop | Select-Object -First 1
                if (-not $downloadedExe) {
                    throw "Downloaded Starship archive does not contain starship.exe"
                }

                New-Item -ItemType Directory -Path $installDir -Force | Out-Null
                Copy-Item -Path $downloadedExe.FullName -Destination $installExe -Force

                # Ensure install dir is on machine PATH for future sessions.
                $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
                if ($machinePath -notlike "*$installDir*") {
                    [Environment]::SetEnvironmentVariable("Path", "$machinePath;$installDir", "Machine")
                }

                Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Green "Starship installed from GitHub release: $installExe"
            } else {
                throw "Could not find Starship Windows ZIP asset for architecture '$targetArch' in latest release."
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

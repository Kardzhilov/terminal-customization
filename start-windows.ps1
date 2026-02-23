#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap script for Windows terminal customization.
    Run this in the built-in Windows PowerShell 5.1 (or any PowerShell).
    It ensures PowerShell 7+ is installed, then hands off to the main setup.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Colour helpers (works in both PS 5.1 and 7+) ──
function Write-Cyan    { param([string]$Text) Write-Host $Text -ForegroundColor Cyan }
function Write-Green   { param([string]$Text) Write-Host $Text -ForegroundColor Green }
function Write-Yellow  { param([string]$Text) Write-Host $Text -ForegroundColor Yellow }
function Write-Red     { param([string]$Text) Write-Host $Text -ForegroundColor Red }
function Write-Magenta { param([string]$Text) Write-Host $Text -ForegroundColor Magenta }

# ── Ensure we're running as Administrator ──
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    Write-Yellow "This script requires Administrator privileges (for font installation, etc.)."
    Write-Yellow "Relaunching as Administrator..."
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# ── Resolve repo root (script is at repo root) ──
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Cyan "========================================="
Write-Cyan "  Windows Terminal Customization Setup"
Write-Cyan "========================================="
Write-Host ""

# ── Step 1: Ensure winget is available ──
function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-WingetAvailable)) {
    Write-Yellow "winget is not available on this system."
    Write-Yellow "Attempting to install App Installer (winget) from Microsoft..."

    # Try to install via Add-AppxPackage from the latest GitHub release
    try {
        $progressPreference = 'SilentlyContinue'

        # Dependencies needed for winget
        Write-Yellow "Installing dependencies..."
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe -ErrorAction SilentlyContinue
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe -ErrorAction SilentlyContinue

        # Download and install latest winget
        $wingetUrl = "https://aka.ms/getwinget"
        $wingetPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller.msixbundle"
        Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath -UseBasicParsing
        Add-AppxPackage -Path $wingetPath -ErrorAction Stop

        $progressPreference = 'Continue'

        if (Test-WingetAvailable) {
            Write-Green "winget installed successfully."
        } else {
            throw "winget still not available after installation attempt."
        }
    } catch {
        Write-Red "Could not install winget automatically."
        Write-Yellow "Please install 'App Installer' from the Microsoft Store and re-run this script."
        Write-Host "https://apps.microsoft.com/detail/9NBLGGH4NNS1"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Green "winget is available."

# ── Step 2: Install PowerShell 7+ if not present ──
function Find-Pwsh {
    # Check common locations and PATH
    $candidates = @(
        @(
            (Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
            "$env:ProgramFiles\PowerShell\7\pwsh.exe",
            "$env:ProgramFiles\PowerShell\8\pwsh.exe",
            "$env:ProgramFiles\PowerShell\9\pwsh.exe"
        ) | Where-Object { $_ -and (Test-Path $_) }
    )

    if ($candidates.Count -gt 0) {
        return $candidates[0]
    }

    # Search for any pwsh.exe under the PowerShell program folder
    $pwshDir = Join-Path $env:ProgramFiles "PowerShell"
    if (Test-Path $pwshDir) {
        $found = Get-ChildItem -Path $pwshDir -Filter "pwsh.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.FullName }
    }

    return $null
}

$pwshPath = Find-Pwsh

if (-not $pwshPath) {
    Write-Yellow "PowerShell 7+ is not installed. Installing via winget..."

    # Reset winget sources to address stale/corrupt source index errors (e.g. 0x8a15000f)
    Write-Yellow "Resetting winget sources..."
    winget source reset --force 2>&1 | Out-Null

    winget install --id Microsoft.PowerShell --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Yellow "winget install failed. Falling back to direct GitHub MSI download..."
        try {
            $progressPreference = 'SilentlyContinue'

            # Detect architecture
            $arch = if ([System.Environment]::Is64BitOperatingSystem) {
                if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
            } else { 'x86' }

            Write-Yellow "Fetching latest PowerShell release from GitHub..."
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" -UseBasicParsing -ErrorAction Stop
            $asset = $release.assets | Where-Object { $_.name -match "win-$arch\.msi$" } | Select-Object -First 1

            if (-not $asset) {
                throw "Could not find a win-$arch MSI in the latest PowerShell release."
            }

            $msiPath = Join-Path $env:TEMP "PowerShell-install.msi"
            Write-Yellow "Downloading $($asset.name)..."
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $msiPath -UseBasicParsing -ErrorAction Stop

            Write-Yellow "Installing $($asset.name)..."
            $msiArgs = "/i `"$msiPath`" /qn ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1"
            $proc = Start-Process msiexec.exe -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
            Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
            $progressPreference = 'Continue'

            if ($proc.ExitCode -ne 0) {
                throw "MSI installer exited with code $($proc.ExitCode)."
            }
            Write-Green "PowerShell installed via MSI."
        } catch {
            Write-Red "Failed to install PowerShell 7+: $($_.Exception.Message)"
            Write-Yellow "Please install PowerShell manually: https://aka.ms/powershell"
            Read-Host "Press Enter to exit"
            exit 1
        }
    }

    # Refresh PATH for this session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    $pwshPath = Find-Pwsh

    if (-not $pwshPath) {
        Write-Red "PowerShell 7+ was installed but could not be found."
        Write-Yellow "Try closing and re-opening this terminal, then run the script again."
        Read-Host "Press Enter to exit"
        exit 1
    }
}

$pwshVersion = & $pwshPath -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
Write-Green "PowerShell $pwshVersion found at: $pwshPath"

# ── Step 3: Hand off to the main setup in PowerShell 7+ ──
$setupScript = Join-Path $RepoRoot "windows\setup.ps1"

if (-not (Test-Path $setupScript)) {
    Write-Red "Could not find windows\setup.ps1 in the repository."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Cyan "Launching main setup in PowerShell 7+..."
Write-Host ""

& $pwshPath -NoProfile -ExecutionPolicy Bypass -File $setupScript -RepoRoot $RepoRoot

$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    Write-Red "Setup exited with code $exitCode."
}

Read-Host "Press Enter to close"
exit $exitCode

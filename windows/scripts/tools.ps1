#Requires -Version 7.0
<#
.SYNOPSIS
    Installs CLI tools: zoxide (smart cd) and fzf (fuzzy finder), plus the PSFzf module.
    Install priority: Scoop → winget → direct GitHub binary download (no admin/installer needed).
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

Write-Cyan "── Tools Installation (zoxide · fzf · PSFzf) ──"

# ── User-local bin dir (no admin needed) ──────────────────────
$userBin = Join-Path $env:USERPROFILE ".local\bin"
if (-not (Test-Path $userBin)) {
    New-Item -ItemType Directory -Path $userBin -Force | Out-Null
}

# Add to PATH for this session and persistently for the user
function Add-ToUserPath {
    param([string]$Dir)
    $currentUser = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentUser -notlike "*$Dir*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$currentUser;$Dir", "User")
        Write-Green "  Added $Dir to user PATH."
    }
    if ($env:Path -notlike "*$Dir*") {
        $env:Path += ";$Dir"
    }
}
Add-ToUserPath $userBin

# Also add scoop shims if scoop exists
$scoopShims = Join-Path $env:USERPROFILE "scoop\shims"
if (Test-Path $scoopShims) { Add-ToUserPath $scoopShims }

# ── Package manager helpers ────────────────────────────────────
function Test-Scoop { return [bool](Get-Command scoop -ErrorAction SilentlyContinue) }
function Test-Winget { return [bool](Get-Command winget -ErrorAction SilentlyContinue) }

# ── Ensure Scoop is available ──────────────────────────────────
if (-not (Test-Scoop)) {
    Write-Yellow "  Scoop not found. Attempting to install Scoop..."
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Add-ToUserPath $scoopShims
        if (Test-Scoop) {
            Write-Green "  Scoop installed."
        } else {
            throw "Scoop not on PATH after install."
        }
    } catch {
        Write-Yellow "  Scoop install blocked ($($_.Exception.Message)) — will try winget then direct download."
    }
}

# ── Download a single-exe tool from GitHub releases ───────────
function Install-GithubBinary {
    param(
        [string]$Name,
        [string]$Repo,          # e.g. "ajeetdsouza/zoxide"
        [string]$AssetPattern,  # regex to match the right zip asset
        [string]$ExeName        # the exe filename inside the zip
    )

    Write-Yellow "  Installing $Name via direct GitHub download..."
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing -ErrorAction Stop
        $asset = $release.assets | Where-Object { $_.name -match $AssetPattern } | Select-Object -First 1
        if (-not $asset) { throw "No matching asset found for pattern '$AssetPattern'." }

        $zipPath = Join-Path $env:TEMP "$Name-download.zip"
        Write-Yellow "  Downloading $($asset.name)..."
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop

        $extractDir = Join-Path $env:TEMP "$Name-extract"
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        $exePath = Get-ChildItem -Path $extractDir -Filter $ExeName -Recurse | Select-Object -First 1
        if (-not $exePath) { throw "$ExeName not found in downloaded archive." }

        Copy-Item -Path $exePath.FullName -Destination (Join-Path $userBin $ExeName) -Force
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue

        Write-Green "  $Name installed to $userBin\$ExeName."
        return $true
    } catch {
        Write-Red "  Failed to install $Name via GitHub download: $($_.Exception.Message)"
        return $false
    }
}

# ── Main install function — Scoop → winget → GitHub binary ────
function Install-Tool {
    param(
        [string]$Name,
        [string]$ScoopName,
        [string]$WingetId,
        [string]$Command,
        [string]$GithubRepo,
        [string]$GithubAssetPattern,
        [string]$GithubExeName
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Green "  $Name already installed."
        return
    }

    # 1. Scoop
    if (Test-Scoop) {
        Write-Yellow "  Installing $Name via Scoop..."
        scoop install $ScoopName 2>&1 | Out-Null
        Add-ToUserPath $scoopShims
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            Write-Green "  $Name installed via Scoop."
            return
        }
        Write-Yellow "  Scoop install of $Name failed."
    }

    # 2. winget
    if (Test-Winget) {
        Write-Yellow "  Installing $Name via winget..."
        winget install --id $WingetId --source winget --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            Write-Green "  $Name installed via winget."
            return
        }
        Write-Yellow "  winget install of $Name failed."
    }

    # 3. Direct GitHub binary download (no admin, no installer)
    $ok = Install-GithubBinary -Name $Name -Repo $GithubRepo `
              -AssetPattern $GithubAssetPattern -ExeName $GithubExeName
    if (-not $ok) {
        Write-Red "  Could not install $Name by any method. Please install manually."
        Write-Red "  https://github.com/$GithubRepo/releases/latest"
    }
}

# ── zoxide ────────────────────────────────────────────────────
Install-Tool -Name "zoxide" `
    -ScoopName "zoxide" `
    -WingetId "ajeetdsouza.zoxide" `
    -Command "zoxide" `
    -GithubRepo "ajeetdsouza/zoxide" `
    -GithubAssetPattern "x86_64-pc-windows-msvc\.zip$" `
    -GithubExeName "zoxide.exe"

# ── fzf ───────────────────────────────────────────────────────
Install-Tool -Name "fzf" `
    -ScoopName "fzf" `
    -WingetId "junegunn.fzf" `
    -Command "fzf" `
    -GithubRepo "junegunn/fzf" `
    -GithubAssetPattern "fzf-.*-windows_amd64\.zip$" `
    -GithubExeName "fzf.exe"

# ── PSFzf — PowerShell fzf integration ────────────────────────
$psfzf = Get-Module -ListAvailable -Name PSFzf | Sort-Object Version -Descending | Select-Object -First 1

if (-not $psfzf) {
    Write-Yellow "  Installing PSFzf module..."
    Install-Module -Name PSFzf -Force -SkipPublisherCheck -Scope CurrentUser
    Write-Green "  PSFzf installed."
} else {
    Write-Green "  PSFzf $($psfzf.Version) already installed."
}

Write-Green "Tools setup complete."
exit 0

param(
    [Parameter(Mandatory)]
    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"

function Write-Cyan    { param([string]$Text) Write-Host $Text -ForegroundColor Cyan }
function Write-Green   { param([string]$Text) Write-Host $Text -ForegroundColor Green }
function Write-Yellow  { param([string]$Text) Write-Host $Text -ForegroundColor Yellow }
function Write-Red     { param([string]$Text) Write-Host $Text -ForegroundColor Red }

Write-Cyan "── Tools Installation (zoxide · fzf · PSFzf) ──"

# ── Ensure Scoop is available ──────────────────────────────────
function Test-Scoop { return [bool](Get-Command scoop -ErrorAction SilentlyContinue) }

if (-not (Test-Scoop)) {
    Write-Yellow "  Scoop not found. Installing Scoop..."
    try {
        # Scoop requires execution policy to allow remote scripts for current user
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (Test-Scoop) {
            Write-Green "  Scoop installed."
        } else {
            throw "Scoop not on PATH after install."
        }
    } catch {
        Write-Red "  Failed to install Scoop: $($_.Exception.Message)"
    }
}

# ── Helper: install a tool via Scoop, fall back to winget ──────
function Install-Tool {
    param(
        [string]$Name,
        [string]$ScoopName,
        [string]$WingetId,
        [string]$Command
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Green "  $Name already installed."
        return
    }

    # Try Scoop first
    if (Test-Scoop) {
        Write-Yellow "  Installing $Name via Scoop..."
        scoop install $ScoopName 2>&1 | Out-Null
        # Refresh PATH after scoop install
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" +
                    (Join-Path $env:USERPROFILE "scoop\shims")
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            Write-Green "  $Name installed via Scoop."
            return
        }
        Write-Yellow "  Scoop install of $Name failed, trying winget..."
    }

    # Fallback to winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Yellow "  Installing $Name via winget..."
        winget install --id $WingetId --source winget --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            Write-Green "  $Name installed via winget."
            return
        }
    }

    Write-Red "  Could not install $Name — please install it manually."
}

# ── zoxide — smart directory jumping ──────────────────────────
Install-Tool -Name "zoxide" -ScoopName "zoxide" -WingetId "ajeetdsouza.zoxide" -Command "zoxide"

# ── fzf — fuzzy finder (required by PSFzf) ────────────────────
Install-Tool -Name "fzf" -ScoopName "fzf" -WingetId "junegunn.fzf" -Command "fzf"

# ── PSFzf — PowerShell fzf integration ────────────────────────
$psfzf = Get-Module -ListAvailable -Name PSFzf | Sort-Object Version -Descending | Select-Object -First 1

if (-not $psfzf) {
    Write-Yellow "  Installing PSFzf module..."
    Install-Module -Name PSFzf -Force -SkipPublisherCheck -Scope CurrentUser
    Write-Green "  PSFzf installed."
} else {
    Write-Green "  PSFzf $($psfzf.Version) already installed."
}

Write-Green "Tools setup complete."
exit 0

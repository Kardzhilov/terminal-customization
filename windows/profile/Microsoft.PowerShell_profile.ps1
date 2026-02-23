# ╔══════════════════════════════════════════════════════════════════╗
# ║  PowerShell 7+ Profile — Terminal Customization                 ║
# ║  Starship · PSReadLine · zoxide · PSFzf                          ║
# ╚══════════════════════════════════════════════════════════════════╝

# ── Cached init helper ───────────────────────────────────────────
# Runs $Command and caches stdout to $CacheFile.
# Re-generates only when the tool's version string changes.
function Import-CachedInit {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [string]$CacheFile,
        [string]$VersionCommand   # command to get version string (to detect upgrades)
    )
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) { return }

    $cacheDir = Split-Path $CacheFile
    if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }

    $versionFile = "$CacheFile.ver"
    $currentVersion = & $Command $VersionCommand 2>&1 | Select-Object -First 1

    $needsRegen = (-not (Test-Path $CacheFile)) -or
                  (-not (Test-Path $versionFile)) -or
                  ((Get-Content $versionFile -Raw) -ne $currentVersion)

    if ($needsRegen) {
        & $Command @Arguments | Set-Content $CacheFile
        Set-Content $versionFile $currentVersion
    }

    . $CacheFile
}

$cacheDir = Join-Path $env:LOCALAPPDATA "powershell-profile-cache"

# ── Starship Prompt ──────────────────────────────────────────────
$env:STARSHIP_CONFIG = Join-Path $env:USERPROFILE ".config" "starship.toml"
Import-CachedInit -Command "starship" `
    -Arguments @("init", "powershell", "--print-full-init") `
    -CacheFile (Join-Path $cacheDir "starship.ps1") `
    -VersionCommand "--version"

# ── PSReadLine — zsh-like Autosuggestions & Syntax Highlighting ──
# PSReadLine is built into PS7 — import directly, no ListAvailable scan needed
Import-Module PSReadLine -ErrorAction SilentlyContinue

if (Get-Module PSReadLine) {
    # Prediction / Autosuggestions (like zsh-autosuggestions)
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView

    # History settings
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -MaximumHistoryCount 10000

    # Syntax highlighting colours — Gruvbox inspired (like zsh-syntax-highlighting)
    Set-PSReadLineOption -Colors @{
        Command            = "#A9B665"   # green — commands
        Parameter          = "#7DAEA3"   # blue — parameters
        Operator           = "#D3869B"   # purple — operators
        Variable           = "#D8A657"   # yellow — variables
        String             = "#A9B665"   # green — strings
        Number             = "#D3869B"   # purple — numbers
        Type               = "#89B482"   # cyan — types
        Comment            = "#928374"   # grey — comments
        Keyword            = "#EA6962"   # red — keywords
        Member             = "#7DAEA3"   # blue — member access
        Error              = "#EA6962"   # red — errors
        Selection          = "#504945"   # dark bg — selection
        InlinePrediction   = "#928374"   # grey — inline ghost text
        ListPrediction     = "#D4BE98"   # foreground — list items
        ListPredictionSelected = "#D8A657" # yellow — selected list item
    }

    # Key bindings
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord "Ctrl+LeftArrow" -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord "Ctrl+d" -Function DeleteCharOrExit
    Set-PSReadLineKeyHandler -Chord "Ctrl+a" -Function BeginningOfLine
    Set-PSReadLineKeyHandler -Chord "Ctrl+e" -Function EndOfLine

    # Accept autosuggestion with Right Arrow (like zsh-autosuggestions)
    Set-PSReadLineKeyHandler -Key RightArrow -ScriptBlock {
        param($key, $arg)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($cursor -lt $line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion($key, $arg)
        }
    }
}

# ── Zoxide — smart cd (learns your most-used dirs) ───────────────
# 'z foo'   — jump to best match · 'zi foo' — interactive pick · 'z -' — previous dir
Import-CachedInit -Command "zoxide" `
    -Arguments @("init", "powershell") `
    -CacheFile (Join-Path $cacheDir "zoxide.ps1") `
    -VersionCommand "--version"

# ── PSFzf — fuzzy finder (lazy-loaded on first use) ──────────────
# Ctrl+T: file search · Ctrl+R: history · Alt+C: cd · Alt+A: history insert
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    # Stub key handlers that load PSFzf on first use instead of at startup
    function _Load-PSFzf {
        if (-not (Get-Module PSFzf)) {
            Import-Module PSFzf -ErrorAction SilentlyContinue
            if (Get-Module PSFzf) {
                Set-PsFzfOption -PSReadlineChordProvider     'Ctrl+t'
                Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
                Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock { Invoke-FuzzySetLocation }
                Set-PSReadLineKeyHandler -Chord 'Alt+a' -ScriptBlock { Invoke-FuzzyHistory }
            }
        }
    }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock { _Load-PSFzf; Invoke-FzfPipelineInput }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock { _Load-PSFzf; Invoke-FuzzyHistory }
    Set-PSReadLineKeyHandler -Chord 'Alt+c'  -ScriptBlock { _Load-PSFzf; Invoke-FuzzySetLocation }
    Set-PSReadLineKeyHandler -Chord 'Alt+a'  -ScriptBlock { _Load-PSFzf; Invoke-FuzzyHistory }
}

# ── Aliases ──────────────────────────────────────────────────────
Set-Alias -Name ll -Value Get-ChildItem -Option AllScope
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function ..... { Set-Location ..\..\..\.. }
function l { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
function which($command) { Get-Command $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path }
function pullall {
    Get-ChildItem -Directory | ForEach-Object {
        Write-Host "Pulling $($_.Name)..." -ForegroundColor Cyan
        git -C $_.FullName pull
    }
}
function update { winget upgrade --all --include-unknown }
function e. { explorer.exe . }
Set-Alias -Name cls -Value Clear-Host -Option AllScope
# ╔══════════════════════════════════════════════════════════════════╗
# ║  PowerShell 7+ Profile — Terminal Customization                 ║
# ║  Starship prompt · PSReadLine autosuggestions & highlighting    ║
# ╚══════════════════════════════════════════════════════════════════╝

# ── Starship Prompt ──────────────────────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ── PSReadLine — zsh-like Autosuggestions & Syntax Highlighting ──
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine

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

# ── Aliases (Windows equivalents of the Linux aliases) ──────────
# Navigation
Set-Alias -Name ll -Value Get-ChildItem -Option AllScope
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function ..... { Set-Location ..\..\..\.. }

# ls with colours (PowerShell already colours Get-ChildItem output)
function l { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }

# Quick edit
function which($command) { Get-Command $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path }

# Git pull all repos in current directory
function pullall {
    Get-ChildItem -Directory | ForEach-Object {
        Write-Host "Pulling $($_.Name)..." -ForegroundColor Cyan
        git -C $_.FullName pull
    }
}

# Update (winget upgrade)
function update { winget upgrade --all --include-unknown }

# Clear with alias
Set-Alias -Name cls -Value Clear-Host -Option AllScope

# Open explorer in current directory
function e. { explorer.exe . }

# ── Environment ──────────────────────────────────────────────────
$env:STARSHIP_CONFIG = Join-Path $env:USERPROFILE ".config" "starship.toml"

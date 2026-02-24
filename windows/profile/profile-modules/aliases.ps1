# ── General Aliases & Helpers ─────────────────────────────────────
Set-Alias -Name ll -Value Get-ChildItem -Option AllScope
Set-Alias -Name cls -Value Clear-Host -Option AllScope

function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function ..... { Set-Location ..\..\..\.. }
function l { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
function which($command) { Get-Command $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path }
function update { winget upgrade --all --include-unknown }
function e. { explorer.exe . }

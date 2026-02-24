# ── Starship Prompt ──────────────────────────────────────────────
if (-not (Get-Command starship -ErrorAction SilentlyContinue)) { return }

$env:STARSHIP_CONFIG = Join-Path (Join-Path $env:USERPROFILE ".config") "starship.toml"
Import-CachedInit -Command "starship" `
    -Arguments @("init", "powershell", "--print-full-init") `
    -CacheFile (Join-Path $script:cacheDir "starship.ps1") `
    -VersionCommand "--version"

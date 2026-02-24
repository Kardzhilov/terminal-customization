# ── Zoxide — smart cd (learns your most-used dirs) ───────────────
# 'z foo'   — jump to best match · 'zi foo' — interactive pick · 'z -' — previous dir
if (-not (Get-Command zoxide -ErrorAction SilentlyContinue)) { return }

Import-CachedInit -Command "zoxide" `
    -Arguments @("init", "powershell") `
    -CacheFile (Join-Path $script:cacheDir "zoxide.ps1") `
    -VersionCommand "--version"

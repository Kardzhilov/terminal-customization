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

$script:cacheDir = Join-Path $env:LOCALAPPDATA "powershell-profile-cache"

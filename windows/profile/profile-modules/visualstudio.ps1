# ── Visual Studio ────────────────────────────────────────────────
$_vswhere = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe",
    "$env:ProgramFiles\Microsoft Visual Studio\Installer\vswhere.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $_vswhere) { return }

$_devenv = & $_vswhere -latest -products * -find "Common7\IDE\devenv.exe"
if (-not $_devenv) { return }

# Cache the resolved devenv path so the function doesn't re-query every call
$script:_vsDevenvPath = $_devenv

function vs {
    param(
        [Parameter(Position=0)]
        [string]$Path = "."
    )

    $full = Resolve-Path $Path
    $sln = Get-ChildItem -Path $full -Filter *.sln -ErrorAction SilentlyContinue |
           Select-Object -First 1

    if ($sln) {
        Start-Process -FilePath $script:_vsDevenvPath -ArgumentList "`"$($sln.FullName)`""
    } else {
        Start-Process -FilePath $script:_vsDevenvPath -ArgumentList "`"$($full.Path)`""
    }
}

Remove-Variable _vswhere, _devenv -ErrorAction SilentlyContinue

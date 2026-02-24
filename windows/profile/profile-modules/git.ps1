# ── Git helpers ──────────────────────────────────────────────────
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return }

function pullall {
    Get-ChildItem -Directory | ForEach-Object {
        Write-Host "Pulling $($_.Name)..." -ForegroundColor Cyan
        git -C $_.FullName pull
    }
}

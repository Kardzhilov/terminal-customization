# ── VS Code ──────────────────────────────────────────────────────
if (-not (Get-Command code -ErrorAction SilentlyContinue)) { return }

function c { code . }

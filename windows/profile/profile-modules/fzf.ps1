# ── PSFzf — fuzzy finder (lazy-loaded on first use) ──────────────
# Ctrl+T: file search · Ctrl+R: history · Alt+C: cd · Alt+A: history insert
if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { return }

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

# ╔══════════════════════════════════════════════════════════════════╗
# ║  PowerShell 7+ Profile — Terminal Customization                 ║
# ║  Modular — each module checks its own dependencies              ║
# ╚══════════════════════════════════════════════════════════════════╝

# ── Resolve module directory (co-located with this profile) ──────
$_profileDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$_modulesDir = Join-Path $_profileDir "profile-modules"

# ── Load order matters: core first, then the rest ────────────────
# Each module silently returns if its dependencies are missing.
$_modules = @(
    "core"            # Import-CachedInit helper + $cacheDir
    "starship"        # Starship prompt        (needs: starship)
    "psreadline"      # PSReadLine config       (needs: PSReadLine module)
    "zoxide"          # Zoxide smart cd         (needs: zoxide)
    "fzf"             # PSFzf fuzzy finder      (needs: fzf)
    "aliases"         # General aliases & navigation
    "git"             # Git helpers             (needs: git)
    "vscode"          # VS Code shortcuts       (needs: code)
    "visualstudio"    # Visual Studio launcher  (needs: vswhere + devenv)
)

foreach ($_mod in $_modules) {
    $_modPath = Join-Path $_modulesDir "$_mod.ps1"
    if (Test-Path $_modPath) { . $_modPath }
}

Remove-Variable _profileDir, _modulesDir, _modules, _mod, _modPath -ErrorAction SilentlyContinue
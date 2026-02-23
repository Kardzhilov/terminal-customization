# Terminal Customization

This repository contains scripts for customizing terminals according to my personal preference. Both **Linux** and **Windows** are supported.

## Description

The scripts in this repository are designed to modify the appearance and functionality of terminals to enhance user experience. This includes changes to color schemes, prompt layout, command aliases, and more.

---

## Linux

### Dependencies

* Linux OS (specifically distributions that use the `apt-get` package manager, such as Ubuntu, Debian, etc.)
* Terminal emulator like GNOME Terminal, Konsole, etc.

### Installing

Clone the repository and run the setup:
```bash
git clone https://github.com/Kardzhilov/terminal-customization.git
cd terminal-customization
./start-linux.sh
```

### What it does
- Installs **Zsh** with Oh My Zsh, zsh-autosuggestions, and zsh-syntax-highlighting
- Installs **Starship** prompt with the gruvbox-rainbow preset
- Configures aliases and plugins

---

## Windows

### Dependencies

* Windows 10 (build 1809+) or Windows 11
* The setup will install everything else automatically (winget, PowerShell 7+, Starship, fonts)

### Installing

Clone the repository and run the bootstrap script in **any PowerShell** (including the built-in Windows PowerShell 5.1):

```powershell
git clone https://github.com/Kardzhilov/terminal-customization.git
cd terminal-customization

# Run as Administrator (the script will self-elevate if needed)
powershell -ExecutionPolicy Bypass -File .\start-windows.ps1
```

### What it does

1. **Installs PowerShell 7+** via winget (handles future major versions like 8, 9, etc.)
2. **Installs MesloLGS NF fonts** from the `fonts/` directory into the system
3. **Installs Starship** prompt with the gruvbox-rainbow preset (same theme as Linux)
4. **Configures PSReadLine** for:
   - History-based autosuggestions (like zsh-autosuggestions)
   - Syntax highlighting with Gruvbox colours (like zsh-syntax-highlighting)
   - ListView prediction view for interactive completions
   - Tab completion menu, arrow-key history search
5. **Installs zoxide** — smart `cd` that learns your most-used directories (`z foo`, `zi` for interactive)
6. **Installs fzf + PSFzf** — fuzzy finder with `Ctrl+T` (files), `Ctrl+R` (history), `Alt+C` (cd)
   - Uses **Scoop** as the primary package manager (installs it if not present), winget as fallback
7. **Installs a PowerShell profile** with aliases and all configurations

### Repository structure
```
fonts/                          # Shared — MesloLGS NF font files
theme/                          # Shared — Windows Terminal colour schemes

start-linux.sh                  # Linux entry point
start-windows.ps1               # Windows entry point (runs in PS 5.1, installs PS 7+)

linux/
    alias/                      # Shell aliases
    scripts/                    # Setup scripts (zsh, starship, git, etc.)

windows/
    setup.ps1                   # Main orchestrator (runs in PowerShell 7+)
    scripts/
        fonts.ps1               # Font installation
        starship.ps1            # Starship installation & config
        psreadline.ps1          # PSReadLine setup
        tools.ps1               # zoxide, fzf, PSFzf installation
        profile.ps1             # Profile installation
    profile/
        Microsoft.PowerShell_profile.ps1  # The profile loaded on every pwsh session
```

---

## Checklist

- [ ] Review and run the setup script for your OS
- [ ] Check if the terminal appearance and functionality seems right
- [ ] Import the Gruvbox colour scheme from `theme/windows-terminal-colours.json` into Windows Terminal
- [ ] Set the terminal font to **MesloLGS NF** in your terminal settings

## To-Do
- Add support for other Linux package managers (e.g. `yum`, `dnf`, etc.)
- Add more tools to the tools list

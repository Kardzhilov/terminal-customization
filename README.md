# Terminal Customization

This repository contains scripts for customizing Linux terminals according to my personal preference.

## Description

The scripts in this repository are designed to modify the appearance and functionality of Linux terminals to enhance user experience. This includes changes to color schemes, prompt layout, command aliases, and more.

## Getting Started

### Dependencies

* Linux OS (specifically distributions that use the `apt-get` package manager, such as Ubuntu, Debian, etc.)
* Terminal emulator like GNOME Terminal, Konsole, etc.

### Installing

* Clone the repository to your local machine and run the `shell-customizations.sh` script.
```bash
git clone https://github.com/Kardzhilov/terminal-customization.git

./terminal-customization/shell-customizations.sh
```
## Checklist

- [ ] Review and run `shell-customizations.sh` script.
- [ ] Check if the terminal appearance and functionality seems right.
- [ ] Modify windows terminal colour json file to match the Gruvbox theme `theme/windows-terminal-colours.json`
- [ ] Install the fonts in the `fonts` directory. And set the terminal font to one of the installed fonts.
- [ ] Look for Gruvbox theme plugins for Visual Studio Code.
- [ ] Look for Gruvbox theme plugins for IntelliJ IDEA.

## To-Do
- Add support for other package managers (e.g. `yum`, `dnf`, etc.)
- Add more tools to the tools list.

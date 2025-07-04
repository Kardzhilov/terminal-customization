#!/bin/bash

# Source the colors file
source ./scripts/colours.sh

# Function to handle errors and exit, otherwise the script would continue running even if there is an exit 1
exit_with_error() {
    echo "${RED}Something went wrong.${NC} Exiting..."
    exit 1
}

read -p "Would you like to customize your ${GREEN}Terminal${NC}? (Y/N): " choice

# Convert the choice to uppercase
choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')

# Check the user's choice
if [ "$choice" == "Y" ]; then
    echo "${GREEN}Continuing with the script...${NC}"
elif [ "$choice" == "N" ]; then
    echo "${GREEN}Have a nice day${NC}"
    exit 0
else
    exit_with_error
fi

# Update the apt package list before installing new packages
sudo apt-get update

./scripts/zsh.sh || exit_with_error
echo "" # Add a new line for legibility
./scripts/starship.sh || exit_with_error
echo ""
./scripts/tools.sh || exit_with_error
echo ""
./scripts/git.sh || exit_with_error
echo ""

# Ask if Homebrew should be installed
read -p "Would you like to install ${MAGENTA}Homebrew${NC}? (Y/N): " brew_choice

# Convert the choice to uppercase
brew_choice=$(echo "$brew_choice" | tr '[:lower:]' '[:upper:]')

# Check the user's choice
if [ "$brew_choice" == "Y" ]; then
    # Check if running on ARM processor
    if [ "$(uname -p)" = "aarch64" ] || [ "$(uname -p)" = "arm64" ]; then
        echo "${YELLOW}ARM processor detected. Homebrew is not supported on ARM architecture.${NC}"
        echo "${GREEN}Skipping Homebrew installation${NC}"
    else
        echo "${GREEN}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit_with_error
    fi
elif [ "$brew_choice" == "N" ]; then
    echo "${GREEN}Skipping Homebrew installation${NC}"
else
    exit_with_error
fi

./scripts/newsboat.sh || exit_with_error
echo ""
./scripts/rainbow.sh "Customization Complete" || exit_with_error

echo "${YELLOW}Remember to go over the checklist in the README.md file${NC}"
echo "${CYAN}You should probably restart your terminal now to avoid bugs${NC}"

# Start zsh if it is installed
if command -v zsh &>/dev/null; then
    exec zsh -l
fi

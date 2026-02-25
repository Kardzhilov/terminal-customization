#!/bin/bash

# Source the colors file
source ./scripts/colours.sh

# Check for server flag
SERVER_MODE=false
if [ "$1" == "server" ] || [ "$1" == "--server" ] || [ "$1" == "-server" ]; then
    SERVER_MODE=true
    echo "${GREEN}Server mode: Installing Starship automatically${NC}"
    choice="Y"
else
    read -p "Would you like to install and setup ${MAGENTA}Starship Shell Prompt${NC}? (Y/N): " choice
fi

# Convert the choice to uppercase
choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')

# Check the user's choice
if [ "$choice" == "Y" ]; then
    echo "${GREEN}Continuing with the script...${NC}"
elif [ "$choice" == "N" ]; then
    echo "${GREEN}Skipping Starship, you should probably install oh-my-zsh in that case.${NC}"
    exit 0
else
    exit 1
fi

############### Install Starship Prompt ###############

# Install Starship if not already installed
if ! command -v starship &>/dev/null; then
    echo "${YELLOW}Installing Starship...${NC}"
    curl -sS https://starship.rs/install.sh | sh
    mkdir -p ~/.config/
fi

# Add Starship initialization to .zshrc if not already present
if ! grep -q "eval \"\$(starship init zsh)\"" ~/.zshrc; then
    echo "${YELLOW}Adding Starship initialization to .zshrc...${NC}"
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
fi

# Run starship preset if configuration file doesn't exist
if [ ! -f ~/.config/starship.toml ]; then
    echo "${YELLOW}Running Starship preset...${NC}"
    starship preset gruvbox-rainbow -o ~/.config/starship.toml
fi

# Function to check if the [time] section is present and disabled in the starship.toml file
time_section_disabled() {
    # Check if the [time] section exists and is disabled
    if grep -q "\[time\]" "$1" && grep -q "disabled = true" "$1"; then
        return 0
    else
        return 1
    fi
}

# Edit ~/.config/starship.toml to disable time module if not already disabled
if ! time_section_disabled ~/.config/starship.toml; then
    echo "${YELLOW}Disabling time module in Starship configuration...${NC}"
    sed -i '/^\[time\]/,/^\[/ s/^disabled = false/disabled = true/' ~/.config/starship.toml
fi

echo "${GREEN}Starship installation and configuration completed.${NC}"

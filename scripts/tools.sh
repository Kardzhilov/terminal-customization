#!/bin/bash

# Source the colors file
source ./scripts/colours.sh

read -p "Would you like to install and setup ${MAGENTA}tools${NC}? (Y/N): " choice

# Convert the choice to uppercase
choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')

# Check the user's choice
if [ "$choice" == "Y" ]; then
    echo "${GREEN}Continuing with the script...${NC}"
elif [ "$choice" == "N" ]; then
    echo "${GREEN}Skipping newsboat${NC}"
    exit 0
else
    exit 1
fi

# Install apt packages if not installed
if ! command -v batman &>/dev/null; then
    echo "${GREEN}Starting bat/batman setup${NC}"
    sudo apt-get install -y bat
fi

echo "${GREEN}Tools setup complete${NC}"

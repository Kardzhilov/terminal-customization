#!/bin/bash

# Source the colors file
source ./scripts/colours.sh


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
    exit 1
fi

# Update the apt package list before installing new packages
sudo apt-get update

./scripts/zsh.sh
echo "" # Add a for legibility
./scripts/starship.sh
echo ""
./scripts/tools.sh
echo ""
./scripts/newsboat.sh
echo ""
./scripts/rainbow.sh "Customization Complete"

echo "${YELLOW}Remember to go over the checklist in the README.md file${NC}"
echo "${GREEN}Please restart your terminal to see the changes.${NC}"

#!/bin/bash

# Source the colors file
source ./scripts/colours.sh

read -p "Would you like to configure ${MAGENTA}Git${NC} and ${MAGENTA}GitHub CLI${NC}? (Y/N): " choice

# Convert the choice to uppercase
choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')

# Check the user's choice
if [ "$choice" == "Y" ]; then
    echo "${GREEN}Continuing with Git and GitHub CLI setup...${NC}"
elif [ "$choice" == "N" ]; then
    echo "${GREEN}Skipping Git configuration${NC}"
    exit 0
else
    exit 1
fi

# Install Git if not already installed
if ! command -v git &> /dev/null; then
    echo "${GREEN}Installing Git...${NC}"
    sudo apt-get install -y git || exit 1
else
    echo "${GREEN}Git is already installed${NC}"
fi

# Install GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "${GREEN}Installing GitHub CLI...${NC}"

    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y gh || exit 1
else
    echo "${GREEN}GitHub CLI is already installed${NC}"
fi

# Configure Git user information
echo "${CYAN}Setting up Git configuration...${NC}"
read -p "Enter your Git username: " git_username
read -p "Enter your Git email: " git_email

git config --global user.name "$git_username"
git config --global user.email "$git_email"
git config --global init.defaultBranch main
git config --global pull.rebase false

echo "${GREEN}Git configured successfully${NC}"

# Authenticate with GitHub CLI
echo "${CYAN}Setting up GitHub CLI authentication...${NC}"
echo "${YELLOW}This will open a browser window for GitHub authentication${NC}"
gh auth login

# Verify authentication
if gh auth status 2>&1 | grep -q "Logged in to"; then
    echo "${GREEN}GitHub CLI authentication successful!${NC}"
    gh auth setup-git
else
    echo "${RED}GitHub CLI authentication failed${NC}"
    exit 1
fi

echo "${GREEN}Git and GitHub CLI setup complete!${NC}"

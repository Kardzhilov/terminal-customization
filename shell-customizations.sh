#!/bin/bash

# Define text color variables
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT_BLACK=$(tput setaf 8)
BRIGHT_RED=$(tput setaf 9)
BRIGHT_GREEN=$(tput setaf 10)
NC=$(tput sgr0) # No Color

# Install Zsh if not installed
if ! command -v zsh &>/dev/null; then
    echo "${YELLOW}Installing Zsh...${NC}"
    sudo apt-get update
    sudo apt-get install -y zsh
fi

# Create .zshrc if not exists
if [ ! -f ~/.zshrc ]; then
    echo "${YELLOW}Creating .zshrc file...${NC}"
    touch ~/.zshrc
fi

# Function to add aliases block to .zshrc
add_alias_block() {
    local block_start="# <>< git managed aliases start ><>"
    local block_end="# <>< git managed aliases end ><>"

    # Check if block already exists
    if ! grep -q "$block_start" ~/.zshrc; then
        # Add aliases block to .zshrc
        echo "${YELLOW}Adding aliases to .zshrc...${NC}"
        echo "$block_start" >> ~/.zshrc
        cat "$1" >> ~/.zshrc
        echo "$block_end" >> ~/.zshrc
    fi
}

# Prompt the user for choice and add aliases based on the choice
read -p "${CYAN}Do you want full aliases or just basic aliases? (full/basic): ${NC}" choice
if [ "$choice" = "full" ]; then
    add_alias_block "alias/general"
    add_alias_block "alias/tools"
elif [ "$choice" != "basic" ]; then
    echo "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi

echo "${GREEN}Zsh installed and aliases added to .zshrc.${NC}"

# Directory to clone the repositories
plugins_dir="$HOME/.zsh-plugins"
mkdir -p "$plugins_dir"

# Function to add plugins block to .zshrc
add_plugins() {
    local plugins_start="# <>< git managed plugins start ><>"
    local plugins_end="# <>< git managed plugins end ><>"

    # Check if block already exists
    if ! grep -q "$plugins_start" ~/.zshrc; then
        # Add plugins block to .zshrc
        echo "${YELLOW}Adding plugins to .zshrc...${NC}"
        echo "$plugins_start" >> ~/.zshrc
        echo 'plugins=(' >> ~/.zshrc
        echo '  zsh-autosuggestions' >> ~/.zshrc
        echo '  zsh-syntax-highlighting' >> ~/.zshrc
        echo ')' >> ~/.zshrc
        echo "$plugins_end" >> ~/.zshrc
    fi
}

# Install zsh-autosuggestions if not already installed
install_zsh_autosuggestions() {
    local autosuggestions_dir="$plugins_dir/zsh-autosuggestions"
    if [ ! -d "$autosuggestions_dir" ]; then
        echo "${YELLOW}Installing zsh-autosuggestions...${NC}"
        git clone https://github.com/zsh-users/zsh-autosuggestions "$autosuggestions_dir"
        # Add sourcing to .zshrc
        if ! grep -q "source $autosuggestions_dir/zsh-autosuggestions.zsh" ~/.zshrc; then
            echo "source $autosuggestions_dir/zsh-autosuggestions.zsh" >> ~/.zshrc
        fi
    fi
}

# Install zsh-syntax-highlighting if not already installed
install_zsh_syntax_highlighting() {
    local syntax_highlighting_dir="$plugins_dir/zsh-syntax-highlighting"
    if [ ! -d "$syntax_highlighting_dir" ]; then
        echo "${YELLOW}Installing zsh-syntax-highlighting...${NC}"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$syntax_highlighting_dir"
        # Add sourcing to .zshrc
        if ! grep -q "source $syntax_highlighting_dir/zsh-syntax-highlighting.zsh" ~/.zshrc; then
            echo "source $syntax_highlighting_dir/zsh-syntax-highlighting.zsh" >> ~/.zshrc
        fi
    fi
}

# Add plugins to .zshrc
add_plugins

# Install zsh-autosuggestions
install_zsh_autosuggestions

# Install zsh-syntax-highlighting
install_zsh_syntax_highlighting

echo "${GREEN}Plugins added to .zshrc.${NC}"

# Install Starship if not already installed
if ! command -v starship &>/dev/null; then
    echo "${YELLOW}Installing Starship...${NC}"
    curl -sS https://starship.rs/install.sh | sh
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
    sed -i 's/\[time\]/\[time\]\ndisabled = true/g' ~/.config/starship.toml
fi

echo "${GREEN}Starship installation and configuration completed.${NC}"

# Set Zsh as the default shell
echo "${CYAN}Setting Zsh as the default shell...${NC}"
chsh -s $(which zsh)
echo "${GREEN}Zsh is now the default shell.${NC}"

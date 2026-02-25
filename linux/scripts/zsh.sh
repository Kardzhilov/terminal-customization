#!/bin/bash

# Source the colors file
source ./scripts/colours.sh

# Check for server flag
SERVER_MODE=false
if [ "$1" == "server" ] || [ "$1" == "--server" ] || [ "$1" == "-server" ]; then
    SERVER_MODE=true
fi

echo "${GREEN}Starting ZSH setup${NC}"

# Install zsh if not installed
if ! command -v zsh &>/dev/null; then
    echo "${YELLOW}Installing zsh...${NC}"
    sudo apt-get install -y zsh
fi

# Create .zshrc if not exists
if [ ! -f ~/.zshrc ]; then
    echo "${YELLOW}Creating .zshrc file...${NC}"
    touch ~/.zshrc
fi

# Install Oh My Zsh if not installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "${YELLOW}Installing Oh My Zsh...${NC}"
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended
fi

# Empty .zshrc file if "# <><" is not found
if ! grep -q "# <><" ~/.zshrc; then
    echo "${YELLOW}Emptying .zshrc file...${NC}"
    > ~/.zshrc
fi

# Add export ZSH="$HOME/.oh-my-zsh" to the start of .zshrc if not already present
if ! grep -Fxq 'export ZSH="$HOME/.oh-my-zsh"' ~/.zshrc; then
    echo "${YELLOW}Adding export ZSH=\"$HOME/.oh-my-zsh\" to .zshrc...${NC}"
    echo 'export ZSH="$HOME/.oh-my-zsh"' > ~/.zshrc_temp
    echo "" >> ~/.zshrc_temp
    cat ~/.zshrc >> ~/.zshrc_temp
    mv ~/.zshrc_temp ~/.zshrc
fi

# Add key bindings to .zshrc if not already present
if ! grep -q 'bindkey "\^\[\[1;5C" forward-word' ~/.zshrc || ! grep -q 'bindkey "\^\[\[1;5D" backward-word' ~/.zshrc; then
    echo "${YELLOW}Adding key bindings to .zshrc...${NC}"
    echo 'bindkey "^[[1;5C" forward-word' >> ~/.zshrc  # Ctrl + Right Arrow
    echo 'bindkey "^[[1;5D" backward-word' >> ~/.zshrc  # Ctrl + Left Arrow
fi

clear_alias_block() {
    local block_start="# <>< git managed aliases start ><>"
    local block_end="# <>< git managed aliases end ><>"

    if grep -q "$block_start" ~/.zshrc; then
        # Remove existing block
        sed -i "/$block_start/,/$block_end/d" ~/.zshrc
    fi
}

############### Add Aliases to .zshrc ###############
# Function to add aliases block to .zshrc
add_alias_block() {
    local block_start="# <>< git managed aliases start ><>"
    local block_end="# <>< git managed aliases end ><>"
    local file_contents=$(cat "$1")
    touch ~/.zshrc_temp

    # Check if block already exists
    if grep -q "$block_start" ~/.zshrc; then
        # Preserve existing aliases block
        sed -n "/$block_start/,/$block_end/{/$block_start/b; /$block_end/b; p}" ~/.zshrc >> ~/.zshrc_temp
        sed -i "/$block_start/,/$block_end/d" ~/.zshrc
    fi

    # Add aliases block to .zshrc
    echo "${YELLOW}Adding aliases to .zshrc...${NC}"
    echo "$block_start" >> ~/.zshrc
    # Add preserved aliases block back
    cat ~/.zshrc_temp >> ~/.zshrc
    echo "$file_contents" >> ~/.zshrc
    echo "$block_end" >> ~/.zshrc
    rm -f ~/.zshrc_temp
}

# Prompt the user for choice and add aliases based on the choice
if [ "$SERVER_MODE" = true ]; then
    echo "${GREEN}Server mode: Installing full aliases${NC}"
    choice="full"
else
    read -p "${CYAN}Do you want full aliases or just basic aliases? (full/basic): ${NC}" choice
fi

if [ "$choice" = "full" ]; then
    clear_alias_block
    add_alias_block "alias/general"
    add_alias_block "alias/tools"
elif [ "$choice" = "basic" ]; then
    clear_alias_block
    add_alias_block "alias/general"
else
    echo "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi

echo "${GREEN}Zsh installed and aliases added to .zshrc.${NC}"

############### add plugins to .zshrc ###############
# Directory to clone the repositories
plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
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
        echo '  git' >> ~/.zshrc
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
    fi
}

# Install zsh-syntax-highlighting if not already installed
install_zsh_syntax_highlighting() {
    local syntax_highlighting_dir="$plugins_dir/zsh-syntax-highlighting"
    if [ ! -d "$syntax_highlighting_dir" ]; then
        echo "${YELLOW}Installing zsh-syntax-highlighting...${NC}"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$syntax_highlighting_dir"
    fi
}

# Add plugins to .zshrc
add_plugins

# Install zsh-autosuggestions
install_zsh_autosuggestions

# Install zsh-syntax-highlighting
install_zsh_syntax_highlighting

echo "${GREEN}Plugins added to .zshrc.${NC}"

# Add source $ZSH/oh-my-zsh.sh to.zshrc (needs to be after plugins)
if ! grep -Fxq 'source $ZSH/oh-my-zsh.sh' ~/.zshrc; then
    echo "${YELLOW}Adding source \$ZSH/oh-my-zsh.sh to .zshrc...${NC}"
    echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc
fi

# Add zoxide init to .zshrc (needs to be after oh-my-zsh source)
if ! grep -q 'zoxide init zsh' ~/.zshrc; then
    echo "${YELLOW}Adding zoxide init to .zshrc...${NC}"
    echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
fi

# Set Zsh as the default shell
echo "${CYAN}Setting Zsh as the default shell...${NC}"
chsh -s $(which zsh)
echo "${GREEN}Zsh is now the default shell.${NC}"

#!/bin/bash

# Source the colors file
source ./scripts/colours.sh

read -p "Would you like to install and setup ${MAGENTA}newsboat${NC}? (Y/N): " choice

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

# Install Newsboat if not already installed
if ! command -v newsboat &> /dev/null; then
    sudo apt-get install newsboat -y
    mkdir ~/.newsboat
fi

# Add content to ~/.newsboat/config if not already present
if [ ! -f ~/.newsboat/config ]; then
    cat <<EOF > ~/.newsboat/config
datetime-format "%m.%d %H:%M"
bind-key RIGHT open
bind-key LEFT quit
auto-reload yes
max-items 100
color article                              color223 color236
color background                           color100 color236
color info                                 color142 color235
color listfocus                            color214 color239
color listfocus_unread                     color214 color96
color listnormal                           color246 color237
color listnormal_unread                    color175 color237
highlight article "^Feed:.*"               color175 color237
highlight article "^Title:.*"              color214 color237 bold
highlight article "^Author:.*"             color167 color237
highlight article "^Link:.*"               color109 color237
highlight article "^Date:.*"               color142 color237
highlight article "\\[[0-9]\\+\\]"         color208 color237 bold
highlight article "\\[[^0-9].*[0-9]\\+\\]" color167 color237 bold
EOF
fi

# Add content to ~/.newsboat/urls if not already present
if [ ! -f ~/.newsboat/urls ]; then
    cat <<EOF > ~/.newsboat/urls
https://www.nrk.no/nyheter/siste.rss "~NRK"
#https://www.aljazeera.com/xml/rss/all.xml "~Al-Jazeera"
#http://feeds.bbci.co.uk/news/world/rss.xml "~BBC World News"
#https://www.theguardian.com/international/rss "~The Guardian"
#http://rss.nytimes.com/services/xml/rss/nyt/World.xml "~The New York Times"
#http://feeds.washingtonpost.com/rss/world "~The Washington Post"
EOF
fi

# Add cron job to run newsboat -x reload every hour if not already added
if ! crontab -l | grep -q "newsboat -x reload"; then
    (crontab -l ; echo "0 * * * * newsboat -x reload") | sort - | uniq - | crontab -
fi

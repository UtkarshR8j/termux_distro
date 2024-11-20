#!/bin/bash

# Enable verbose output for debugging
set -x

# Function to display styled messages
print_message() {
    local message=$1
    local color=$2
    case $color in
        "green") echo -e "\033[1;32m$message\033[0m" ;;
        "yellow") echo -e "\033[1;33m$message\033[0m" ;;
        "blue") echo -e "\033[1;34m$message\033[0m" ;;
        "red") echo -e "\033[1;31m$message\033[0m" ;;
        *) echo "$message" ;;
    esac
}

# Step 1: Install Python and pyftpdlib package
print_message "=== Installing Python and pyftpdlib ===" "blue"
pkg update && pkg upgrade -y
pkg install python -y
pip install pyftpdlib

# Step 2: Check if Termux storage permission is granted
print_message "=== Checking storage permission ===" "yellow"
if [ ! -d "$HOME/storage" ]; then
    print_message "Termux storage permission not granted. Granting now..." "red"
    termux-setup-storage
    print_message "Termux storage permission granted." "green"
else
    print_message "Termux storage permission already granted." "green"
fi

# Step 3: Start FTP Server with pyftpdlib
print_message "=== Starting FTP server ===" "blue"

# Set FTP server port and shared directory (adjust the directory if needed)
FTP_PORT=2122
FTP_DIR="$HOME"

print_message "Starting FTP server at port $FTP_PORT with write permissions, sharing $FTP_DIR" "yellow"
python -m pyftpdlib -p $FTP_PORT -w -d $FTP_DIR

print_message "FTP server is now running. You can access it using FTP on your computer at ftp://<phone_ip_address>:$FTP_PORT/" "green"
print_message "To find your local IP address, run 'ifconfig' in Termux and look for the wlan IP." "yellow"


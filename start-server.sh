#!/bin/bash

# Enable verbose output for debugging and seeing each command executed
set -x

# Function to print styled messages
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

# Step 1: Check if tmux is installed, if not, install it
if ! command -v tmux &> /dev/null; then
    print_message "tmux not found, installing it..." "yellow"
    pkg install tmux -y
    print_message "tmux installed successfully." "green"
else
    print_message "tmux is already installed." "green"
fi

# Step 2: Start SSH in Termux using tmux
print_message "=== Step 2: Starting SSH Server in Termux ===" "blue"

# Check if tmux session for SSH already exists
tmux has-session -t termux-ssh 2>/dev/null
if [ $? != 0 ]; then
    tmux new-session -d -s termux-ssh "sshd -D"   # Start SSH in detached tmux session
    print_message "Started SSH server in Termux using tmux." "green"
else
    print_message "SSH server in Termux is already running." "green"
fi

# Step 3: Start Debian in proot and SSH server inside Debian using tmux
print_message "=== Step 3: Starting SSH Server inside Debian ===" "blue"

# Check if tmux session for Debian already exists
tmux has-session -t debian-ssh 2>/dev/null
if [ $? != 0 ]; then
    tmux new-session -d -s debian-ssh "
        proot-distro login debian -- bash -c \"
        echo 'Starting SSH server inside Debian...'
        /usr/sbin/sshd -D
        \""
    print_message "Started SSH server inside Debian using tmux." "green"
else
    print_message "SSH server inside Debian is already running." "green"
fi

# Step 4: Provide instructions to the user
print_message "=== All servers are now running in the background ===" "blue"
print_message "To view logs or interact with any of the sessions, run the following commands:" "yellow"
print_message "  tmux attach-session -t termux-ssh  # For Termux SSH" "yellow"
print_message "  tmux attach-session -t debian-ssh  # For Debian SSH" "yellow"

# End of script


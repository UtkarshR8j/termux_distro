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

# Function to display step counter
step_counter() {
    local current_step=$1
    local total_steps=$2
    echo "Step $current_step of $total_steps"
}

# Total number of steps
total_steps=8
current_step=1

# Step 1: Install OpenSSH and set up SSH in Termux
print_message "=== Step 1: Installing OpenSSH in Termux ===" "blue"
pkg update && pkg upgrade -y

print_message "Updating package lists..." "yellow"
step_counter $current_step $total_steps
((current_step++))

print_message "Installing OpenSSH..." "yellow"
pkg install openssh -y

print_message "OpenSSH installed successfully." "green"
step_counter $current_step $total_steps
((current_step++))

# Step 2: Configuring SSH to listen on port 8022 in Termux
print_message "=== Step 2: Configuring SSH on port 8022 in Termux ===" "blue"
print_message "Configuring SSH to listen on port 8022..." "yellow"
sed -i 's/^#Port 22/Port 8022/' $PREFIX/etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> $PREFIX/etc/ssh/sshd_config
echo "PermitRootLogin yes" >> $PREFIX/etc/ssh/sshd_config

print_message "SSH configuration updated for port 8022." "green"
step_counter $current_step $total_steps
((current_step++))

# Step 3: Set password for Termux default user
print_message "=== Step 3: Setting password for Termux default user ===" "blue"
print_message "Setting password for the default user..." "yellow"
echo -e "utkarsh1850\nutkarsh1850" | passwd
print_message "Password for default user set to 'utkarsh1850'." "green"
step_counter $current_step $total_steps
((current_step++))

# Step 4: Install proot and proot-distro, then install Debian
print_message "=== Step 4: Installing proot and proot-distro ===" "blue"
pkg install proot proot-distro -y
print_message "proot and proot-distro installed successfully." "green"
step_counter $current_step $total_steps
((current_step++))

# Step 5: Installing Debian using proot-distro
print_message "Installing Debian using proot-distro..." "yellow"
proot-distro install debian
print_message "Debian installation completed." "green"
step_counter $current_step $total_steps
((current_step++))

# Step 6: Set up SSH inside Debian
print_message "=== Step 5: Installing and configuring SSH inside Debian ===" "blue"
print_message "Running installation and setup commands inside Debian..." "yellow"

# Run commands inside the Debian environment
proot-distro login debian -- bash -c "
export DEBIAN_FRONTEND=noninteractive
echo 'Updating package list and upgrading packages...'
apt update && apt upgrade -y
echo 'Installing OpenSSH server and sudo inside Debian...'
apt install openssh-server sudo -y
echo 'Creating /run/sshd directory...'
sudo mkdir -p /run/sshd
echo 'Setting correct permissions for /run/sshd...'
sudo chmod 0755 /run/sshd
echo 'Configuring SSH to listen on port 9000 inside Debian...'
sudo sed -i 's/#Port 22/Port 9000/' /etc/ssh/sshd_config
echo 'PasswordAuthentication yes' | sudo tee -a /etc/ssh/sshd_config
echo 'Creating user 'utk' inside Debian...'
sudo useradd -m utk
echo 'Setting password for user 'utk'...'
echo 'utk:utkarsh1850' | sudo chpasswd
"

print_message "SSH service set up and user 'utk' created inside Debian." "green"
step_counter $current_step $total_steps
((current_step++))

# Step 7: Manually start SSH in Debian by logging into the proot environment
print_message "=== Step 6: Starting SSH service inside Debian manually ===" "blue"
print_message "Log into Debian and manually start SSH using /usr/sbin/sshd..." "yellow"

# Login to Debian and run the SSH server directly
proot-distro login debian -- bash -c "
echo 'Starting SSH server inside Debian...'
/usr/sbin/sshd
"

print_message "SSH service started inside Debian manually using /usr/sbin/sshd." "green"
step_counter $current_step $total_steps
((current_step++))

# Step 8: Expose the IP address and give SSH instructions
print_message "=== Step 7: Exposing the IP address for SSH access ===" "blue"

# Fetch IP address for Termux
IP_ADDRESS=$(ip a | grep inet | grep -v inet6 | awk '{print $2}' | cut -d/ -f1)
if [ -z "$IP_ADDRESS" ]; then
    print_message "Could not fetch IP address for Termux." "red"
else
    print_message "Setup complete. To SSH into Termux, use the following command:" "yellow"
    print_message "ssh utk@$IP_ADDRESS -p 8022" "green"
fi

# Fetch IP address for Debian inside proot
DEBIAN_IP_ADDRESS=$(proot-distro login debian -- bash -c "ip a | grep inet | grep -v inet6 | awk '{print $2}' | cut -d/ -f1" )
if [ -z "$DEBIAN_IP_ADDRESS" ]; then
    print_message "Could not fetch IP address for Debian." "red"
else
    print_message "Setup complete. To SSH into Debian, use the following command:" "yellow"
    print_message "ssh utk@$DEBIAN_IP_ADDRESS -p 9000" "green"
fi

print_message "All tasks completed successfully!" "green"

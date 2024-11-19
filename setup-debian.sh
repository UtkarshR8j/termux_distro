#!/bin/bash

# Enable verbose output for debugging and seeing each command executed
set -x

# Function to display progress bar
progress_bar() {
    local i=0
    local total=$1
    local width=50
    local percent=0
    local progress=""
    local completed=""
    local remaining=""

    while [ $i -le $total ]; do
        completed=$(printf "%0.s#" $(seq 1 $((i * width / total)) ))
        remaining=$(printf "%0.s-" $(seq 1 $((width - i * width / total)) ))
        percent=$((i * 100 / total))
        progress="\r[${completed}${remaining}] ${percent}%"
        echo -ne "$progress"
        sleep 0.1
        ((i++))
    done
    echo ""
}

# Step 1: Install OpenSSH and set up SSH in Termux
echo "=== Step 1: Installing OpenSSH in Termux ==="
pkg update && pkg upgrade -y

echo "Updating package lists..."
progress_bar 10

echo "Installing OpenSSH..."
pkg install openssh -y

echo "OpenSSH installed successfully."
progress_bar 20

echo "=== Step 2: Configuring SSH on port 8022 ==="
echo "Configuring SSH to listen on port 8022..."
sed -i 's/^#Port 22/Port 8022/' $PREFIX/etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> $PREFIX/etc/ssh/sshd_config
echo "PermitRootLogin yes" >> $PREFIX/etc/ssh/sshd_config

echo "SSH configuration updated for port 8022."
progress_bar 30

echo "=== Step 3: Setting password for Termux default user ==="
echo "Setting password for the default user..."
echo -e "utkarsh1850\nutkarsh1850" | passwd
echo "Password for default user set to 'utkarsh1850'."
progress_bar 40

echo "Starting SSH service in Termux..."
sshd
echo "SSH service started on port 8022."

# Step 4: Install proot and proot-distro, then install Debian
echo "=== Step 4: Installing proot and proot-distro ==="
pkg install proot proot-distro -y
echo "proot and proot-distro installed successfully."
progress_bar 50

echo "Installing Debian using proot-distro..."
proot-distro install debian
echo "Debian installation completed."
progress_bar 60

# Step 5: Set up and install necessary software inside the Debian environment using proot
echo "=== Step 5: Installing and configuring SSH inside Debian ==="
echo "Running installation and setup commands inside Debian..."

# Run the following steps inside the Debian environment non-interactively
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

echo "SSH service set up and user 'utk' created inside Debian."

# Step 6: Manually start SSH service inside Debian
echo "=== Step 6: Starting SSH service manually inside Debian ==="
echo "Starting SSH daemon manually inside Debian..."
proot-distro login debian -- bash -c "
sudo /usr/sbin/sshd -D
"
echo "SSH service started inside Debian."

# Step 7: Expose the IP address and give SSH instructions
echo "=== Step 7: Exposing the IP address for SSH access ==="
IP_ADDRESS=$(ip a | grep inet | grep -v inet6 | awk '{print $2}' | cut -d/ -f1)
echo "Setup complete. To SSH into Debian, use the following command:"
echo "ssh utk@$IP_ADDRESS -p 9000"

echo "All tasks completed successfully!"
echo "You can now SSH into the Debian environment from any machine on the same network using the command above."

#!/bin/bash

# Check if script is run as root
if [[ $(id -u) -ne 0 ]]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Function to print messages in a specific format
print_message() {
    echo "------------------------------------------------------"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo "------------------------------------------------------"
}

# Update package repositories and upgrade installed packages
print_message "Updating package repositories and upgrading installed packages"
apt update
apt upgrade -y

# Install necessary packages
print_message "Installing necessary packages"
apt install -y vim openssh-server curl wget net-tools

# Partitioning (example: create a 10GB partition mounted at /data)
print_message "Creating partitions"
echo -e "n\np\n\n\n+10G\nw" | fdisk /dev/sda
mkfs.ext4 /dev/sda3  # Replace /dev/sda3 with the appropriate partition

# Mounting partitions
print_message "Mounting partitions"
mkdir /data
mount /dev/sda3 /data

# Configure SSH (optional: adjust as needed)
print_message "Configuring SSH"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
service ssh restart

# Create a new user and add to sudo group
print_message "Creating a new user and adding to sudo group"
username="deployuser"
password="your_password_here"
useradd -m -s /bin/bash "$username"
echo "$username:$password" | chpasswd
usermod -aG sudo "$username"

# Generate SSH keys for the new user (optional: adjust as needed)
print_message "Generating SSH keys for the new user"
sudo -u "$username" ssh-keygen -t rsa -b 4096 -C "$username@example.com" -f /home/"$username"/.ssh/id_rsa -q -N ""

# Example: Deploy additional software (e.g., nginx)
print_message "Installing nginx"
apt install -y nginx

# Configure firewall rules (optional: adjust as needed)
print_message "Configuring firewall rules"
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# Set hostname (optional: replace 'hostname' with your desired hostname)
print_message "Setting hostname"
hostnamectl set-hostname hostname

# Example: Network configuration (optional: adjust as needed)
print_message "Configuring network interfaces"
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
EOF
netplan apply

# Display completion message
print_message "Linux machine deployment completed successfully"
echo "SSH access available for user: $username"
echo "Nginx installed and firewall configured"

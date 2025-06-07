#!/bin/bash
set -euo pipefail

# This script is run by the preseed late_command
# It peforms post-installation tasks on a bare metal Debian system.

# Create SSH directory for root
mkdir -p /root/.ssh

# Download SSH keys from GitHub
wget -O /root/.ssh/authorized_keys https://github.com/nielsmaerten.keys

# Set proper permissions for SSH
chown -R root:root /root/.ssh
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Set hostname
echo "katana" > /etc/hostname
echo "127.0.1.1 katana.local katana" >> /etc/hosts

# Configure login banner with IP address
IP=$(ip route get 1.1.1.1 | grep -oP "src \\K\\S+")
echo "Katana \\n.\\O \\l [$IP]" > /etc/issue

# Configure SSH security settings
sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
echo "RequiredRSASize 2048" >> /etc/ssh/sshd_config

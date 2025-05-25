# Proxmox VE Installation

This directory contains Ansible playbooks to install and configure Proxmox VE on a Debian-based server.

## Prerequisites

- A fresh Debian installation (preferably from the 100-bare-metal-debian step)
- SSH access to the target server with sudo privileges
- Ansible installed on your local machine

## Installation Steps

1. **Check/update the inventory file**

   Review `inventory.yml`
   - Update `ansible_host` to the IP chosen in step 100.

2. **Run the installation playbook**

   ```bash
   ansible-playbook -i inventory.yml playbook.yml
   ```

3. **Access Proxmox Web Interface**

   After installation completes and the server reboots, you can access the Proxmox web interface at:
   
   https://katana.local:8006

   Login with your root credentials.

# Proxmox VE Installation

This directory contains Ansible playbooks to install and configure Proxmox VE on a Debian-based server.
Based on these instructions: https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_12_Bookworm

## Prerequisites

- A fresh Debian installation (preferably from the 100-bare-metal-debian step)
- SSH access to the target server with sudo privileges
- Ansible installed on your local machine

## Installation Steps

1. **Check/update the inventory file**

   Review `000-common/inventory.yml`
   - Update `ansible_host` to the IP chosen in step 100.

1. **Test SSH access**

   Ensure you can login to the server using root

1. **Run the installation playbook**

   ```bash
   ansible-playbook ./200-install-proxmox/playbook.yml
   ```

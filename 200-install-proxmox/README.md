# Proxmox VE Installation

Ansible playbooks to install and configure Proxmox VE.
Based on: https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_12_Bookworm

## Prerequisites

- A fresh Debian installation (preferably from Step 100)
- Root SSH access to the target server
- Ansible installed on local machine

## Installation Steps

1. **Find server IP**
   After installation, take note of the IP displayed on the login screen

1. **Check/update the inventory file**

   Review `000-common/inventory.yml`
   - Update `ansible_host` to the correct IP

1. **Test SSH access**

   Ensure you can login to the server using root

1. **Run the installation playbook**

   ```bash
   ansible-playbook ./200-install-proxmox/playbook.yml
   ```

## Ansible Playbook Tasks

- SSH setup
- Proxmox VE repositories setup
- Update packages and install Proxmox VE kernel
- Install Proxmox VE packages and supporting tools
- Remove default Debian kernel and update GRUB
# Proxmox VE Post-Installation Configuration

Ansible playbook for configuring Proxmox VE after installation. Sets up networking, packages, and performance optimizations.

## What It Does

1. **Network Bridge**: Creates `vmbr0` bridge for VM/container networking
2. **Packages**: Installs essential tools (htop, iotop, ntp, vim, git, etc.)
3. **Time Sync**: Configures NTP service
4. **Performance**: Sets swappiness to 10 for better VM performance
5. **Logging**: Configures log rotation for Proxmox logs

## Prerequisites

- Proxmox VE already installed
- SSH access with sudo privileges

## Usage

```bash
ansible-playbook -i ../000-common/inventory.yml playbook.yml
```

## Important Notes

**⚠️ Network Configuration**: The playbook modifies `/etc/network/interfaces` and restarts networking. Brief network interruption is expected. Ensure console access if needed.

## Tags

- `network`: Bridge configuration
- `packages`: Package installation  
- `time`: NTP configuration
- `performance`: Kernel optimizations
- `logging`: Log rotation setup

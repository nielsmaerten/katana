# Setting Up Containers on Proxmox

Proxmox VE is now ready to be used. The next steps will vary, but here hare some general guidelines:

## Storage Setup

Suggested ZFS mirror configuration is described in [STORAGE_SETUP.md](./STORAGE_SETUP.md)

## Proxmox Backup Server (PBS)

Essential for most setups. The community installation script has already been downloaded 

1. **Install PBS**  
   Run from Proxmox shell (not via SSH):  
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/proxmox-backup-server.sh)"
   ```

   **Notes:** 
     - As of writing, using a config file with this script does not work. Use manual setup.

1. **Post-Installation Steps**  
   - Run the following command inside the PBS shell:  
     ```bash
     bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pbs-install.sh)"
     ```

Once completed, PBS will be available, and you can begin restoring backups as needed.


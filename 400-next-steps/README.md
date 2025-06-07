# Setting Up Containers on Proxmox

Now that Proxmox is configured, the next step is to set up containers. This process may vary, but here are some general guidelines.

## Proxmox Backup Server (PBS)

Essential for most setups. Follow these steps to install and configure it:

1. **Review Configuration**  
   Check the settings in `/opt/community-scripts/proxmox-backup-server.conf` (created during step 300).

2. **Install PBS**  
   Run the installation script from the Proxmox shell (not via SSH):  
   ```bash
   /root/install-proxmox-backup-server.sh
   ```

3. **Post-Installation Steps**  
   - Connect to the server via SSH and change the default password.  
   - Run the following command inside the PBS shell:  
     ```bash
     bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pbs-install.sh)"
     ```

Once completed, PBS will be available, and you can begin restoring backups as needed.

## Setting up storage / ZFS

A draft setup can be found in [STORAGE_DRAFT.md](./STORAGE_DRAFT.md)
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
     - **⚠️ IMPORTANT:** Create the container as "Privileged". See the section on mount points below.
     - As of writing, using a config file with this script does not work. Use manual setup.

1. **Post-Installation Steps**  
   - Run the following command inside the PBS shell:  
     ```bash
     bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pbs-install.sh)"
     ```

### Linking PBS to the ZFS datastore

Assuming PBS is running in an LXC 101, follow these steps to make the ZFS datastore accessible:

- Make sure the PBS container is Privileged. 
  - If it isn't, you must run PBS installation again, as this cannot be changed after the fact.
  - For a homelab setup, strict isolation is not a priority. Simplicity > managing complex permissions!
  ```bash
  pct config 101 | grep "unprivileged" # Should not return any lines
  ```
- Create a mount point on the Proxmox VE host:  
  ```bash
  pct set 101 -mp0 /tank/pbs-datastore,mp=/tank/pbs-datastore,backup=0
  # backup=0 excludes the mountpoint from backups, preventing loops.
  ```

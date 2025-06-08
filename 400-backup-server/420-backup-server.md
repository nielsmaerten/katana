# Proxmox Backup Server

## Installation

1. **Install PBS**  
   Run from Proxmox shell (not via SSH):  
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/proxmox-backup-server.sh)"
   ```

   **Notes:** 
     - **⚠️ IMPORTANT:** Create the container as "Privileged". See the section on mount points below.
     - As of writing, using a config file with this script does not work. Use manual setup.

1. **Recommended Community Script**  
   - Run the following command inside the PBS shell:  
     ```bash
     bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pbs-install.sh)"
     ```

## Linking PBS to the ZFS datastore

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
- Add datastore "local-zfs" inside PBS:
  ```bash
  pct exec 101 -- proxmox-backup-manager datastore create local-zfs /tank/pbs-datastore
  ```

## Maintenance jobs

Run inside the PBS LXC:

### Pruning schedule

```bash
proxmox-backup-manager prune-job create retention-main \
    --store local-zfs \
    --keep-hourly 168 \
    --keep-daily 30  \
    --keep-weekly 20 \
    --schedule daily \
    --comment "1 week of hourly, 1 month of daily, 6 months of weekly"
```

### Garbage collection (weekly)

```bash
proxmox-backup-manager datastore update local-zfs --gc-schedule weekly
```

### Verification

```bash
proxmox-backup-manager verify-job create verify-new \
    --store local-zfs \
    --schedule "Sun 04:00" \
    --ignore-verified true \
    --comment "Verify newly added blocks (nightly)"

proxmox-backup-manager verify-job create verify-full \
    --store local-zfs \
    --schedule "Sun *-*-1..7 03:00" \
    --ignore-verified true \
    --outdated-after 90 \
    --comment "Full validation of the entire dataset (first Sunday of the month)"
```

## Notifications

Run inside the PBS LXC:

```bash
# Use ntfy to send notifications - generate topic name at random
NTFY_URL=https://ntfy.niels.me/$(openssl rand -hex 12)
proxmox-backup-manager notification endpoint webhook create \
    ntfy --url $NTFY_URL --method post
echo TODO: Subscribe to $NTFY_URL

proxmox-backup-manager \
    notification matcher create ntfy-alerts \
    --match-severity warning,error \
    --target ntfy \
    --comment "Alert me when something fails"
```

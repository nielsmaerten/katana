# Setting Up Backups on Proxmox

Proxmox VE is now ready to be used. The next steps will vary, but here hare some general guidelines:

## [Storage Setup](./410-storage-setup.md)

- Suggested ZFS mirror configuration.

## [Proxmox Backup Server (PBS)](./420-backup-server.md)

- Essential for most setups. The community installation script has already been downloaded.

## [Restic Backup to S3](./430-restic-backup/README.md)

- Set up automated backups of the PBS datastore to S3-compatible storage using Restic.
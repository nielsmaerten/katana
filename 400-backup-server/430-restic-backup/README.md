# Restic Backup to S3

This step sets up Restic to back up the PBS datastore to an S3-compatible endpoint. The backup runs daily on the Proxmox VE host and maintains a 14-day retention policy.

## Prerequisites

- Proxmox VE host with Restic installed
- PBS datastore mounted at `/tank/pbs-datastore`
- S3-compatible storage endpoint with credentials

## Configuration

The Ansible playbook `playbook.yml` will:

1. **Install Restic** (if not already present)
2. **Create .env file** for restic repository and credentials
3. **Set up cron scripts** for daily backups and weekly cleanup

## Running the Playbook

```bash
ansible-playbook 400-backup-server/430-restic-backup/playbook.yml
```

## Backup Schedule

- **Daily backups**: Run via `/etc/cron.daily/restic-backup`
- **Weekly cleanup**: Run via `/etc/cron.weekly/restic-cleanup`, keeping 14 days of snapshots

## Manual Operations

ℹ️ `source /etc/restic/.env` before running these commands:

### Check backup status
```bash
restic snapshots
```

### Run backup manually
```bash
/etc/cron.daily/restic-backup
```

### Check backup logs
```bash
journalctl -t restic-backup
```

### Restore from backup
```bash
# List snapshots
restic snapshots

# Mount a snapshot for browsing
mkdir /tmp/restic-mount
restic mount /tmp/restic-mount

# Restore specific files
restic restore latest --target /restore/path --include /tank/pbs-datastore/specific-file
```

## Security Notes

- Credentials are stored in `/etc/restic/.env` with restricted permissions (600)
- The Restic password should be stored securely and backed up separately


# Restic Backup to S3

This step sets up Restic to back up the PBS datastore to an S3-compatible endpoint. The backup runs daily on the Proxmox VE host and maintains a 14-day retention policy.

## Prerequisites

- Proxmox VE host with Restic installed
- PBS datastore mounted at `/tank/pbs-datastore`
- S3-compatible storage endpoint with credentials

## Configuration

The Ansible playbook `431-restic.yml` will:

1. **Install Restic** (if not already present)
2. **Create configuration files** for S3 credentials and repository settings
3. **Initialize the Restic repository** (if it doesn't exist)
4. **Set up cron scripts** for daily backups and weekly cleanup
5. **Configure 14-day retention** policy

## Environment Variables

1. **Copy the example file**:
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env`** with your actual values & source it

## Running the Playbook

```bash
ansible-playbook 400-backup-server/431-restic.yml
```

## Backup Schedule

- **Daily backups**: Run via `/etc/cron.daily/restic-backup`
- **Weekly cleanup**: Run via `/etc/cron.weekly/restic-cleanup`, keeping 14 days of snapshots

## Manual Operations

### Check backup status
```bash
restic -r $RESTIC_REPOSITORY snapshots
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
restic -r $RESTIC_REPOSITORY snapshots

# Mount a snapshot for browsing
mkdir /tmp/restic-mount
restic -r $RESTIC_REPOSITORY mount /tmp/restic-mount

# Restore specific files
restic -r $RESTIC_REPOSITORY restore latest --target /restore/path --include /tank/pbs-datastore/specific-file
```

## Security Notes

- Credentials are stored in `/etc/restic/env` with restricted permissions (600)
- The Restic password should be stored securely and backed up separately
- Consider using IAM roles or other credential management solutions for production environments

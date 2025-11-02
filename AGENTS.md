# AGENTS.md

This guide helps any AI coding assistant understand the Katana repository and respond effectively when working with its code or documentation.

## Repository Purpose

Katana contains scripts and Ansible playbooks for provisioning and managing a home server. Numbered directories mirror the deployment flow:

1. `000-common`: Shared Ansible configuration and inventory files used across multiple steps.
2. `100-bare-metal-debian`: Automated Debian installation resources, including the preseed file that establishes the base operating system.
3. `200-install-proxmox`: Playbooks that install and configure Proxmox VE on the Debian host.
4. `300-configure-proxmox`: Playbooks for post-installation Proxmox configuration and tuning.
5. `400-backup-server`: Documentation and playbooks for storage layout, Proxmox Backup Server, and Restic-based offsite backups.
6. `500-monitoring`: Playbooks and templates for telemetry, alerting, and ntfy-based notifications.
7. `600-updating`: Reserved for ongoing maintenance tasks (currently empty).

## Workflow Overview

AI agents should assume a sequential process when reasoning about infrastructure changes:

1. **Install Debian** using `100-bare-metal-debian/preseed.cfg`.
2. **Install Proxmox VE** with `200-install-proxmox/playbook.yml`.
3. **Apply Proxmox configuration** via `300-configure-proxmox/playbook.yml`.
4. **Prepare storage and backups** following `400-backup-server/410-storage-setup.md` and related playbooks.
5. **Configure monitoring** with `500-monitoring/playbook.yml`.

## Debian Installation Highlights

`100-bare-metal-debian/preseed.cfg` provisions:

- Locale: US English.
- Hostname: `katana`.
- Time zone: `Europe/Brussels`.
- Partitioning: LVM across the entire disk with ext4.
- Users: Creates `niels` with sudo, disables direct root login, disables password authentication, and imports SSH keys from GitHub (`nielsmaerten`).
- Services: SSH server installed.
- Networking: Static IP defaults, with prompts for confirmation during setup.

## Proxmox Installation Details

`200-install-proxmox/playbook.yml`:

- Configures hostname and `/etc/hosts`.
- Adds Proxmox repositories and GPG key.
- Installs the Proxmox kernel and required packages.
- Handles reboots as needed.

## Storage Architecture (`400-backup-server/410-storage-setup.md`)

- **Main SSD (1TB)**: Hosts Proxmox OS and all active VMs/containers via ext4/LVM.
- **Secondary SSD**: Serves as ZFS L2ARC for read caching.
- **HDD ZFS Pool**: Mirrored HDDs for bulk storage, using ZFS features such as lz4 compression and snapshots.

## Repository Layout

- `README.md`: High-level project overview.
- `AGENTS.md`: This guidance.
- `ansible.cfg`: Repository-wide Ansible configuration.
- `000-common/inventory.yml`: Shared inventory used by all playbooks.
- `100-bare-metal-debian/README.md`: Debian installation instructions.
- `100-bare-metal-debian/preseed.cfg`: Automated installer configuration.
- `200-install-proxmox/README.md`: Steps for running the Proxmox playbook.
- `200-install-proxmox/playbook.yml`: Proxmox installation playbook.
- `300-configure-proxmox/playbook.yml`: Post-installation configuration playbook.
- `400-backup-server/410-storage-setup.md`: Manual ZFS storage plan.
- `400-backup-server/420-backup-server.md`: Proxmox Backup Server guidance.
- `400-backup-server/430-restic-backup/`: Assets and playbooks for restic profiles and scheduling.
- `500-monitoring/playbook.yml`: Telemetry and alerting configuration.
- `500-monitoring/README.md`: Monitoring overview.

## Key Considerations for AI Agents

- Storage configuration remains a manual step; existing automation stops before the ZFS setup.
- Assume SSH access to the Debian base system before running Ansible playbooks.
- Keep hostnames and IP addresses consistent between `preseed.cfg` and `000-common/inventory.yml`.
- Secrets such as restic webhook URLs live in `vault/` directories; avoid exposing their contents in responses.
- When in doubt, prefer reading files and summarizing context before proposing changes.
- Follow user instructions carefully and respect any sandbox or execution constraints reported by the environment.

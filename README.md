# Katana Homelab

*Katana* is my personal home server.  
This repository contains the Ansible playbooks and configuration files to set it up from bare metal.

## Features

- **Automated Setup**: Uses Ansible for provisioning and configuration.
- **Virtualization**: Proxmox VE for managing virtual machines and containers.
- **Storage**:
    - ZFS RAID mirror for data redundancy.
    - Optimized ZFS datasets for media streaming and Proxmox Backup Server (PBS).
- **Backups**:
    - Proxmox Backup Server for local backups with fast rollback capabilities.
    - Restic for encrypted, offsite backups to S3-compatible storage, synced nightly.
- **Security**: SSH public key authentication.
- **Monitoring & Alerts**: Ntfy for notifications on errors and warnings.
- **Essential Tools**: Pre-configured with common utilities like htop, lm-sensors, etc.

## Structure

The setup process is divided into sequential, numbered directories:

- `000-common`: Shared Ansible configurations.
- `100-bare-metal-debian`: Automated Debian installation with preseed configuration.
- `200-install-proxmox`: Ansible playbook for Proxmox VE installation.
- `300-configure-proxmox`: Ansible playbook for Proxmox VE post-installation configuration (networking, tools, performance tuning).
- `400-backup-server`: Configuration for Proxmox Backup Server and Restic offsite backups.
- `500-monitoring`: Configuration for Telegraf and Proxmox VE metrics collection to InfluxDB.

## Getting Started

Follow the `README.md` file within each numbered directory sequentially to deploy the server.

**Note**: This setup is tailored for a specific environment.  
It's open-source, but you'll need to adjust some settings if you want to use it yourself.

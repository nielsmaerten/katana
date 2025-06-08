# Proxmox VE Post-Installation Steps

Proxmox VE installation completed successfully! Follow these steps to complete the setup:

## 1. Connect to the Proxmox Host

```bash
ssh root@{{ ansible_host }}

# Now is a good time to set the root password:
passwd
```

**Important**: Don't reboot yet, the post-install script will handle that.

## 2. Run the Post-Install Script

```bash
bash /root/post-pve-install.sh
```
This script provides options for managing Proxmox VE repositories, including disabling the Enterprise Repo, adding or correcting PVE sources, enabling the No-Subscription Repo, adding the test Repo, disabling the subscription nag, updating Proxmox VE, and rebooting the system.

It is recommended to answer “yes” (y) to all options presented during the process.

> Source: https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install

## 3. Continue with Next Playbook

Once Proxmox is accessible via web interface, continue with Step 300.

# System backup (host OS)

This guide covers how to trigger and verify a manual backup of the Proxmox host using the `system` resticprofile that is deployed by Ansible (`deploy-system-profile.yml`). Guest data on ZFS and PBS is handled elsewhere; this backup protects the NVMe-backed operating system.

## Profile rationale

- **Repository**: `/tank/restic/katana-system` lives on the mirrored HDD pool, so a hardware failure of the NVMe still leaves the snapshots reachable.
- **`run-before` hook**: `vgcfgbackup` captures the LVM metadata (`katana-vg`) on every run. Without it, rebuilding logical volumes after disk loss would require manual recreation.
- **Exclusions**: we drop pseudo filesystems (`/dev`, `/proc`, `/sys`, `/run`), ephemeral temp dirs (`/tmp`, `/var/tmp`), and rebuildable caches (`/var/cache/*`) to avoid noise. `/var/lib/vz` (guest disks) and `/tank/**` are already protected by PBS/ZFS jobs, so excluding them keeps this backup focused on the host OS. `/swapfile` and `/lost+found` are regenerated automatically.
- **Retention**: daily snapshots for a week and weekly snapshots for a month balance recovery points with repository size; pruning keeps the repo healthy.

## Manual backup workflow

1. **Confirm prerequisites**
   - Ensure `/tank` is imported and the repository exists: `ls /tank/restic/katana-system/config`.
   - Confirm the password file is present: `test -f /root/.restic-pass`.
  - Optional: check the scheduled status  
    `resticprofile --config /etc/resticprofile/profiles.yml status --profile system`.

2. **Run a backup on demand**

   ```bash
  resticprofile --config /etc/resticprofile/profiles.yml run --profile system
   ```

   The command wraps `restic backup` with the predefined source/exclude lists and executes `vgcfgbackup` first. Expect the run to complete in a few minutes; the first run copies ~7 GB (mostly `/usr`).

3. **Inspect the snapshot**

   ```bash
  resticprofile --config /etc/resticprofile/profiles.yml snapshots --profile system
   ```

   Note the snapshot ID and timestamp. Because we exclude large caches, size growth between runs should be modest unless system packages change significantly.

4. **Optional integrity check**

   ```bash
  resticprofile --config /etc/resticprofile/profiles.yml check --profile system --read-data-subset=5%
   ```

   A partial read check (default schedule runs weekly at 03:00) confirms repository health without scanning every block.

## When to adjust the profile

- If new large caches appear under `/var/cache`, add them to the exclude list to avoid bloating the repo.
- If you introduce new local-only configuration paths (custom scripts, secrets outside `/etc` or `/root`), verify they are under `/` and not excluded.
- Retention and scheduling are set to daily 02:30 backups with a weekly Sunday prune. Modify `system-resticprofile.yml` if you need a different cadence, then rerun the Ansible playbook to deploy changes.

With the profile in place, every manual or scheduled run captures `/boot`, `/etc`, `/usr`, `/var` configuration, `/root`, and the LVM map—everything required to rebuild the host alongside PBS/ZFS guest restores.

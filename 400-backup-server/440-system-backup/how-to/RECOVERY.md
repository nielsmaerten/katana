# Rebuilding the katana host from a restic backup

This tutorial walks through a full bare-metal recovery of the katana Proxmox host after the NVMe system disk has failed. We will reinstall the operating system files, recover the LVM layout, and restore services using the restic snapshot stored on the ZFS pool.

## What you need before you start

- A bootable USB or ISO with Proxmox VE or a Debian live environment (anything with a shell and apt is fine).
- Physical access to the disks that hold the ZFS pool (`tank`). The restic repository (`/tank/restic/katana-system`) must be reachable from the live environment. If the repo lives elsewhere (e.g., external disk or NAS), connect it now.
- The restic password (the contents of `/root/.restic-pass`) and any necessary credentials to unlock encrypted media.
- Enough uninterrupted time to complete the process; plan on 30–60 minutes depending on bandwidth and snapshot size.

Throughout the tutorial you will see two types of notes:

- **What**: the exact command or action you should take.
- **Why**: context so you understand the purpose of each step and can adapt it if your environment differs slightly.

---

## Step 1 – Boot into the live environment

- **What**: Boot the machine from the Proxmox or Debian ISO and choose a shell (e.g. “Install Proxmox VE (Debug mode)” or “Rescue mode” → “Execute shell”).
- **Why**: We need a minimal Linux environment to manipulate disks, import the ZFS pool, and run restic. The debug shell gives root access without installing anything yet.

Once you have a shell, make sure networking works if you expect to install packages from the internet:

```bash
ip addr show
ping -c 3 deb.debian.org
```

If you are offline, copy the required packages onto the ISO in advance or use an alternate mirror in your local network.

---

## Step 2 – Import the ZFS pool that holds the backup

- **What**:

```bash
zpool import
zpool import tank
zfs mount -a
ls /tank/restic/katana-system
```

- **Why**: The restic repository lives on the mirrored HDD pool (`tank`). Importing the pool makes the repository available under `/tank`. The final `ls` confirms the repo files (config, snapshots, etc.) are present. If you do not see them, double-check that you connected the correct disks.

> **Tip**: If the pool was not exported cleanly you might need `zpool import -f tank`. Use `-o altroot=/mnt` if you want to mount the datasets under a different prefix.

---

## Step 3 – Install the tooling inside the live session

- **What**:

```bash
apt-get update
apt-get install --yes restic resticprofile lvm2 zfsutils-linux
```

- **Why**: The live ISO does not ship with restic or resticprofile. Installing them lets us run the same workflows as on the real system. We also install LVM utilities (`lvm2`) because the root filesystem lives on an LVM logical volume.

Copy the restic password into place so commands do not prompt interactively:

```bash
echo "Paste the contents of /root/.restic-pass here" > /root/.restic-pass
chmod 0400 /root/.restic-pass
```

If you keep the password offline, type or paste it carefully. Without it, the repository cannot be opened.

---

## Step 4 – Prepare the replacement NVMe disk

We start from a blank drive because the previous disk is assumed to be destroyed.

1. **Zap any existing partition table**

   ```bash
   sgdisk --zap-all /dev/nvme0n1
   ```

   **Why**: Removing stale metadata eliminates conflicts with the layout we are about to recreate. Adjust the device path if your NVMe drive appears as something else (check with `lsblk`).

2. **Recreate the partition layout**

   ```bash
   sgdisk -n1:1M:+512M -t1:EF00 /dev/nvme0n1
   sgdisk -n2:0:+512M -t2:8300 /dev/nvme0n1
   sgdisk -n3:0:0     -t3:8E00 /dev/nvme0n1
   ```

   **Why**: Partition 1 is the EFI System Partition, partition 2 holds `/boot`, and partition 3 is the physical volume for LVM. These sizes match the original install; you can enlarge `/boot` if desired.

3. **Format the boot partitions**

   ```bash
   mkfs.vfat -F32 /dev/nvme0n1p1
   mkfs.ext2 /dev/nvme0n1p2
   ```

   **Why**: EFI requires FAT32, and `/boot` was previously ext2. Formatting now means the restic restore only has to populate files, not create filesystems.

---

## Step 5 – Restore the LVM metadata

The restic backup contains `/root/vgcfgbackup.katana-vg`, a text snapshot of the volume group layout. We use it to recreate the exact LVM structure.

1. **Extract the metadata file**

   ```bash
   mkdir -p /tmp/system-restore
   restic -r /tank/restic/katana-system \
     --password-file /root/.restic-pass \
     restore latest --target /tmp/system-restore \
     --include /root/vgcfgbackup.katana-vg
   ```

   **Why**: This pulls just the metadata file out of the latest snapshot, keeping the restore quick and making the file easy to inspect.

2. **Read the physical volume UUID**

   ```bash
   grep -A2 "pv0" /tmp/system-restore/root/vgcfgbackup.katana-vg
   ```

   Note the value shown after `id =`. It looks like `vgw2no-...`. We must reuse this UUID so LVM recognizes the PV.

3. **Create the PV and restore the VG**

   ```bash
   pvcreate --restorefile /tmp/system-restore/root/vgcfgbackup.katana-vg \
     --uuid <PV-UUID-from-file> \
     /dev/nvme0n1p3
   vgcfgrestore -f /tmp/system-restore/root/vgcfgbackup.katana-vg katana-vg
   vgchange -ay katana-vg
   lvs -a -o +devices
   ```

   Replace `<PV-UUID-from-file>` with the string you noted.  
   **Why**: `pvcreate` writes a fresh PV header while preserving the original UUID; `vgcfgrestore` replays the VG metadata so the `root` and `swap_1` logical volumes reappear. `vgchange -ay` activates them, and `lvs` confirms everything looks correct.

---

## Step 6 – Mount the target filesystem

- **What**:

```bash
mkdir -p /mnt/root
mount /dev/katana-vg/root /mnt/root
mkdir -p /mnt/root/boot /mnt/root/boot/efi
mount /dev/nvme0n1p2 /mnt/root/boot
mount /dev/nvme0n1p1 /mnt/root/boot/efi
```

- **Why**: We prepare the directory tree where the restic restore will deposit files. Mounting `/boot` and `/boot/efi` ensures their content goes into the right partitions.

Check the mounts with `findmnt /mnt/root /mnt/root/boot /mnt/root/boot/efi`.

---

## Step 7 – Restore the filesystem from restic

- **What**:

```bash
restic -r /tank/restic/katana-system \
  --password-file /root/.restic-pass \
  restore latest --target /mnt/root
```

- **Why**: This pulls the entire snapshot back into place. Because we excluded caches in the backup profile, the restore transfers only the core OS (~7 GB). The command recreates `/etc`, `/usr`, `/var`, `/root`, and all other files that lived on the NVMe.

After the command completes, spot check critical files:

```bash
ls /mnt/root/etc/network/interfaces
ls /mnt/root/root/vgcfgbackup.katana-vg
```

If anything is missing, verify you restored the correct snapshot via `restic snapshots`.

---

## Step 8 – Chroot into the restored system

- **What**:

```bash
mount --bind /dev  /mnt/root/dev
mount --bind /proc /mnt/root/proc
mount --bind /sys  /mnt/root/sys
chroot /mnt/root /bin/bash
```

- **Why**: Chrooting allows us to run package tools and bootloader commands as if we had booted the recovered system. Binding `/dev`, `/proc`, and `/sys` gives the chroot access to devices and kernel pseudo-filesystems.

Inside the chroot, refresh packages and rebuild boot components:

```bash
apt-get update
apt-get install --reinstall proxmox-ve grub-efi-amd64 shim-signed --yes
update-initramfs -u -k all
grub-install /dev/nvme0n1
update-grub
proxmox-boot-tool refresh
systemctl enable resticprofile@system.timer
```

- **Why**:
  - Reinstalling `proxmox-ve` ensures all meta-packages and kernel hooks are present.
  - `update-initramfs` and `proxmox-boot-tool refresh` rebuild boot kernels across all EFI entries.
  - `grub-install` and `update-grub` put the bootloader back onto the new disk.
  - Re-enabling the timer makes nightly restic backups resume automatically once the system is up.

Exit the chroot when finished:

```bash
exit
umount /mnt/root/dev /mnt/root/proc /mnt/root/sys
umount /mnt/root/boot/efi /mnt/root/boot /mnt/root
```

---

## Step 9 – Reboot and validate

1. **Reboot**: `reboot`
2. **Verify the root filesystem**: after boot, run `lsblk` or `df -h` to ensure `/` comes from `/dev/mapper/katana--vg-root`.
3. **Import the ZFS pool** (if it did not import automatically): `zpool import tank`.
4. **Check Proxmox services**:

   ```bash
   systemctl status pvedaemon.service
   systemctl status pve-cluster.service
   ```

5. **Run a test backup** to confirm the recovered system resumes protection:

   ```bash
  resticprofile --config /etc/resticprofile/profiles.yml run --profile system
  resticprofile --config /etc/resticprofile/profiles.yml snapshots --profile system
   ```

6. **Verify PBS restores**: optionally restore a test container or VM to ensure end-to-end readiness.

---

## Additional tips

- Keep offline copies of `/root/.restic-pass` and a printed or encrypted copy of `/root/vgcfgbackup.katana-vg`. They are critical for rebuilding LVM.
- If the restic repository is also mirrored off-site (e.g., via rclone), ensure that sync has caught up before relying on the latest snapshot.
- Consider storing a `dpkg --get-selections` output inside the repo for reference; it helps audit packages during recovery.
- After a successful rebuild, document any deviations you needed (different disk names, larger partitions, etc.) so the next recovery is even smoother.

With these steps completed, the Proxmox host is back to its pre-failure state, ready to manage VMs and containers while nightly backups resume as normal.

---

## Next steps – Restore guests from PBS

You now have the Proxmox host back online, but the guests—including the original PBS container—are still missing. The quickest path is to launch a disposable PBS LXC from a helper script, attach the existing datastore, restore everything (including the old PBS guest) through the Proxmox UI, and finally retire the temporary instance.

### Will this work? Caveats to keep in mind

- The temporary PBS container must run in **privileged** mode with nesting enabled so that `proxmox-backup-server` can access `/dev/fuse` and other required devices. Confirm the helper script creates such a container or adjust it manually.
- Mount the datastore read-write: bind-mount `/tank/pbs-datastore` into the container (for example `mp0: /tank/pbs-datastore,mp=/mnt/pbs-datastore`). Avoid running two PBS instances against the datastore at the same time.
- Certificates and fingerprints will change for the temporary PBS. Proxmox VE will warn you when you connect; that is expected. After restoring the original PBS guest, remove the temporary storage entry to prevent stale fingerprints.
- When you restore the original PBS container, choose **Do not start after restore**. Two PBS services pointing at the same datastore while restores are still running can lead to confusing status output.

With those notes in mind, the workflow below is safe and repeatable.

### 1. Create a temporary PBS container

1. Download and run the helper script from helper-scripts.com that provisions a PBS LXC (follow its README for exact usage).
2. Confirm the container is created privileged, and update `/etc/pve/lxc/<CTID>.conf` if necessary to include:
   ```
   features: nesting=1 keyctl=1
   mp0: /tank/pbs-datastore,mp=/mnt/pbs-datastore,backup=0
   ```
3. Start the container and open a shell inside (`pct enter <CTID>`). Update packages and install PBS if the script did not already:
   ```bash
   apt-get update
   apt-get install --yes proxmox-backup-server
   ```
4. Inside the container, either extract the saved PBS config (`tar -xzf /mnt/pbs-datastore/proxmox-config.tar.gz -C /`) or create a datastore pointing at the bind-mount:
   ```bash
   proxmox-backup-manager datastore create datastore --path /mnt/pbs-datastore
   ```
   Replace `datastore` with the actual name.
5. Enable the PBS service:
   ```bash
   systemctl enable --now proxmox-backup
   ```
   Note the container’s IP (hint: `ip addr show`). You will reach the PBS web UI at `https://<container-ip>:8007/`.

### 2. Register the temporary PBS in Proxmox VE

1. In the Proxmox UI, go to `Datacenter → Storage → Add → Proxmox Backup Server`.
2. Enter the container’s IP, datastore name, and PBS credentials (`root@pam` unless you restored custom users). Accept the new fingerprint.
3. Confirm snapshots appear under the storage’s `Backups` tab.

### 3. Restore guests (including the original PBS)

1. For each VM/LXC you want back, select its snapshot and click **Restore**. Target storage should match your previous layout (`tank-lxc`, `tank-zvol`, etc.).
2. For the original PBS container restore, select the snapshot but **untick “Start after restore”** (or stop it immediately after). We only need it staged for later.
3. Monitor the task logs until all restores finish successfully.

### 4. Swap back to the original PBS instance

1. Remove the temporary storage entry from Proxmox (`Datacenter → Storage → <temp-pbs> → Remove`).
2. Stop the temporary container and clean it up if desired (`pct stop <CTID>`, `pct destroy <CTID>`).
3. Start the restored PBS container (`pct start <original-ctid>`).
4. Re-add the original PBS to Proxmox storage using its IP and fingerprint. Because the datastore lives on `/tank/pbs-datastore`, all snapshots should reappear automatically.

### 5. Final checks

- Trigger a manual backup from the restored PBS (`Datacenter → Storage → <pbs> → Backup → Backup Now`) to ensure the pipeline works.
- Verify scheduled jobs in PBS and Proxmox (cron, systemd timers, etc.) are active.
- Update documentation noting which helper script was used and where to find it for future recoveries.

With the permanent PBS guest back online and Proxmox pointing at it again, the environment matches its pre-failure state: the host OS comes from the restic restore, all guests are back, and backups continue on schedule.

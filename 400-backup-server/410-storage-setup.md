# ZFS Storage Setup

This is just a suggested layout. Adjust for your needs.
We'll use a ZFS mirror pool with two hard disks.

## Overview

- **Pool name:** `tank`
- **Datasets:**
  - `tank/media` — Large media files, e.g. a Jellyfin library
  - `tank/pbs-datastore` — Proxmox Backup Server chunks

## Step-by-Step Instructions

### 1. Identify the disks

Find your disk devices and their stable identifiers:

```bash
# List block devices
lsblk

# Find disk IDs (recommended for ZFS - stable across reboots)
ls -la /dev/disk/by-id/ | grep -E "(ata|scsi|nvme)" | grep -v part

# Check disk information
fdisk -l
```

Note the `/dev/disk/by-id/` paths for your target disks. These are stable identifiers that won't change across reboots, unlike `/dev/sdX` which can change.

Example output:
```
/dev/disk/by-id/ata-WDC_WD40EFRX-68N32N0_WD-WCC7K0123456 -> ../../sdb
/dev/disk/by-id/ata-WDC_WD40EFRX-68N32N0_WD-WCC7K0789012 -> ../../sdc
```

### 1.5. Starting fresh (optional)

If you want to completely reinitialize the disks (⚠️ **THIS WILL DESTROY ALL DATA**):

```bash
# Replace with your actual disk devices
DISK1="/dev/disk/by-id/ata-WDC_WD40EFRX-68N32N0_WD-WCC7K0123456"
DISK2="/dev/disk/by-id/ata-WDC_WD40EFRX-68N32N0_WD-WCC7K0789012"

# Wipe filesystem signatures
wipefs -a $DISK1
wipefs -a $DISK2

# Zero out partition table
sgdisk --zap-all $DISK1
sgdisk --zap-all $DISK2

# Optional: Secure erase (takes a long time, but ensures clean slate)
# dd if=/dev/zero of=$DISK1 bs=1M count=100
# dd if=/dev/zero of=$DISK2 bs=1M count=100
```

### 2. Check Current ZFS Pool Status

First, check if the pool already exists:

```bash
zpool status tank
```

If the command returns successfully (exit code 0), the pool already exists and you can skip to step 5.

### 3. Check for Exported Pools

If the pool doesn't exist, check if it's available for import:

```bash
zpool import
```

### 4. Import or Create the ZFS Pool

#### Option A: Import Existing Pool

If you see "tank" in the import list from step 3:

```bash
zpool import tank
```

#### Option B: Create New Mirror Pool

If the pool doesn't exist and isn't available for import, create it:

**⚠️ IMPORTANT:** Replace the example paths with your actual disk by-id paths from step 1!

```bash
zpool create \
  -o ashift=12 \
  -o autotrim=on \
  tank \
  mirror \
  /dev/disk/by-id/ata-WDC_WD40EFRX-68N32N0_WD-WCC7K0123456 \
  /dev/disk/by-id/ata-WDC_WD40EFRX-68N32N0_WD-WCC7K0789012
```

**Pool creation options explained:**
- `ashift=12` — 4K sector size (2^12 = 4096 bytes); matches modern HDDs and SSDs
- `autotrim=on` — Enable autotrim to reclaim unused space on SSDs; no effect on HDDs

### 5. Create Media Dataset

Create the dataset for sequential media files (Jellyfin):

```bash
zfs create tank/media
```

Apply optimized properties for sequential media workload:

```bash
# Large sequential video files benefit from bigger blocks, providing higher HDD throughput and fewer metadata extents
zfs set recordsize=1M tank/media

# Lightweight compression with negligible CPU overhead; effectively compresses subtitles and metadata even if video is pre-compressed
zfs set compression=lz4 tank/media

# Disables inode access-time updates to avoid read-side writes; Jellyfin doesn't need access times
zfs set atime=off tank/media

# Stores extended attributes in the inode's System Attribute area, reducing seeks over SMB/NFS
zfs set xattr=sa tank/media

# Bulk media copying can tolerate loss of the last few seconds; avoids one rotation latency per write
zfs set sync=disabled tank/media

# Hints that throughput is more important than latency; aligns with sequential media workload
zfs set logbias=throughput tank/media
```

### 6. Create PBS Datastore Dataset

Create the dataset for Proxmox Backup Server:

```bash
zfs create tank/pbs-datastore
```

Apply optimized properties for PBS chunk storage:

```bash
# Matches PBS 4 MiB chunk size (4 blocks per chunk) for optimal prefetch and garbage collection performance
zfs set recordsize=1M tank/pbs-datastore

# Fast compression with small wins on chunk metadata; can switch to zstd-fast later if CPU is plentiful
zfs set compression=lz4 tank/pbs-datastore

# Backups don't need last-access timestamps; saves needless writes
zfs set atime=off tank/pbs-datastore

# Millions of small chunk files benefit when extended attributes live in the inode
zfs set xattr=sa tank/pbs-datastore

# PBS never calls fsync(); following Proxmox documentation removes HDD latency penalty
zfs set sync=disabled tank/pbs-datastore

# Prefers bulk write bandwidth over latency; complements disabled sync
zfs set logbias=throughput tank/pbs-datastore

# Default ARC policy caches both metadata and hot chunks for verify jobs
zfs set primarycache=all tank/pbs-datastore
```

### 7. Verify Configuration

Check the final layout and properties:

```bash
zfs list -o name,used,avail,recordsize,compression,atime,sync
```

You should see output similar to:

```
NAME                USED  AVAIL  RECSIZE  COMPRESS  ATIME  SYNC
tank                282K  1.81T      128K       lz4     on  standard
tank/media           96K  1.81T        1M       lz4    off  disabled
tank/pbs-datastore   96K  1.81T        1M       lz4    off  disabled
```

## Troubleshooting

### Pool Import Issues

If you have trouble importing a pool, you might need to force it:

```bash
zpool import -f tank
```

### Checking Pool Health

Monitor pool status:

```bash
zpool status tank
zpool iostat tank 1
```

### Property Verification

Check individual dataset properties:

```bash
zfs get all tank/media
zfs get all tank/pbs-datastore
```

## Reverting Changes

To destroy the pool (⚠️ **THIS WILL DELETE ALL DATA**):

```bash
zpool destroy tank
```

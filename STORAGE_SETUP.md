## Storage Setup Plan

The storage architecture follows a tiered approach optimizing for both performance and capacity:

### Storage Tiers

1. **Main SSD (1TB OS Drive)**
   - **Purpose**: Proxmox OS and ALL active VM/container storage
   - **Filesystem**: ext4 on LVM
   - **Use Cases**: All production services, databases, web applications, development VMs, active containers
   - **Current Usage**: ~200GB (plenty of room for growth)
   - **Performance**: ~0.1ms latency, 10,000+ IOPS

2. **Secondary SSD (Dedicated ZFS Cache)**
   - **Purpose**: L2ARC cache device for ZFS pool
   - **Configuration**: Dedicated cache device (no local storage)
   - **Benefit**: Maximizes cache effectiveness and ZFS performance
   - **Performance**: Accelerates frequently accessed data from HDD pool

3. **HDD ZFS Pool with Dedicated SSD Cache**
   - **Purpose**: Bulk storage, backups, media, archive data
   - **Configuration**: Mirrored HDDs with SSD L2ARC cache
   - **Filesystem**: ZFS with compression (lz4) and caching
   - **Use Cases**: 
     - Media servers (Plex, etc.)
     - File shares and NAS data
     - VM backups and snapshots
     - Archive storage
     - Cold storage containers
   - **Performance**: 5-15ms latency (cached data much faster)

### ZFS Features Utilized

- **Data Integrity**: Built-in checksumming and error correction
- **Compression**: lz4 compression for space efficiency
- **Snapshots**: Instant, space-efficient backups
- **Cache**: SSD L2ARC for frequently accessed data
- **Send/Receive**: Efficient replication and backup workflows

### Post-Installation Storage Commands

```bash
# Create mirrored HDD ZFS pool
zpool create tank mirror /dev/sdd /dev/sde

# Add dedicated SSD cache device (entire SSD as cache)
zpool add tank cache /dev/sdc

# Configure ZFS optimizations
zfs set compression=lz4 tank
zfs set atime=off tank

# Create datasets for different purposes
zfs create tank/backups      # VM/container backups
zfs create tank/media        # Media files (Plex, etc.)
zfs create tank/shares       # File shares and NAS data
zfs create tank/archive      # Long-term archive storage
```

### Performance Expectations

| Storage Type | VM Boot Time | Database Performance | Best Use Cases |
|--------------|--------------|---------------------|----------------|
| Main SSD (1TB) | 10-30s | Excellent | All active VMs, containers, production services |
| ZFS + Dedicated Cache | 30-90s | Good-Excellent* | Backups, media, file shares (*depending on cache hits) |
| ZFS without Cache | 60-180s | Poor-Fair | Archive storage, infrequent access |

*Cache performance improves significantly over time as frequently accessed data moves to SSD cache.

This setup provides maximum performance where needed while leveraging ZFS advantages for bulk storage and data protection.
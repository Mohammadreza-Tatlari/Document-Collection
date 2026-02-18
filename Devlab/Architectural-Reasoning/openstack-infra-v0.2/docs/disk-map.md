# Disk map – pilot cluster

Record disk serial, size, node, and role (OS vs OSD) for failure-domain planning and runbooks.

## Template

Fill per node. Use `lsblk -o NAME,SIZE,MODEL,SERIAL` and match to physical slots.

| Node       | Device  | Serial   | Size  | Role        | Device class |
|-----------|---------|----------|-------|-------------|--------------|
| node-01   | /dev/sda| (fill)   | 500G  | OS          | -            |
| node-01   | /dev/sdb| (fill)   | 500G  | Ceph OSD    | ssd          |
| compute-01| /dev/sda| (fill)   | 500G  | OS          | -            |
| compute-01| /dev/sdb| (fill)   | 500G  | Ceph OSD    | ssd          |
| compute-01| /dev/sdc| (fill)   | 900G  | Ceph OSD    | hdd          |
| ...       | ...     | ...      | ...   | ...         | ...          |

## Notes

- **OS:** One SSD or partition per node for root; do not share the same disk for OS and OSD without explicit partitioning.
- **SSD (500G):** device_class `ssd`; use for Cinder/Glance pools (volumes, images).
- **HDD (600G/900G/1.2T):** device_class `hdd`; use for backups, vms, or RGW.
- Update this file when adding nodes or replacing disks (see runbooks).

# Pilot disk map

Document disk serial, size, node, and role (OS vs OSD) per server. Update after hardware discovery (e.g. `lsblk -o NAME,SIZE,SERIAL,MODEL`, or from Ceph/Proxmox).

## Template

| Node  | Hostname | Disk (device) | Serial   | Size  | Type | Role |
|-------|----------|---------------|----------|-------|------|------|
| 1     | node1    | -             | -        | -     | -    | Proxmox OS |
| 2     | node2    | /dev/sda      | -        | 500G  | SSD  | OSD  |
| 2     | node2    | /dev/sdb      | -        | 500G  | SSD  | OSD  |
| 2     | node2    | /dev/sdc      | -        | 900G  | HDD  | OSD  |
| ...   | ...      | ...           | ...      | ...   | ...  | ...  |

## Notes

- **SSD:** 10 × 500 GB total across the 5 Ubuntu nodes (e.g. 2 per node). Use device class `ssd` for Ceph.
- **HDD:** Mix of 900 GB, 1.2 TB, 600 GB SATA. Use device class `hdd` for Ceph.
- One disk or partition per node reserved for OS; do not use the same disk for root and OSD without a clear partition layout.
- Run `cephadm ceph-volume inventory` (or `ceph volume inventory`) on each node to list available disks for OSD.

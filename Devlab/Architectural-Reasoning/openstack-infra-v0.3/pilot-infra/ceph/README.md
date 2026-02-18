# Ceph (cephadm)

cephadm spec, OSD layout, CRUSH rules, and pool definitions for the pilot. Ceph runs on the 5 Ubuntu nodes (and optionally MON/MGR on Proxmox VMs).

## Files

- `cephadm-bootstrap.md` – Bootstrap and add-hosts steps
- `specs/` – cephadm service specs (cluster, OSD, MON, MGR)
- `crush-rules.md` – CRUSH rules for ssd/hdd and replication
- `pools.md` – Pool definitions (SSD pool for Cinder, HDD pool optional)

## Device classes

- **ssd** – 10 × 500 GB SSDs (one OSD per disk)
- **hdd** – SATA HDDs (900 GB, 1.2 TB, 600 GB mix)

Replication size 3; CRUSH rule `chooseleaf type host` so replicas are on different hosts.

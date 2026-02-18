# Ceph pools

## SSD pool (Cinder / OpenStack volumes)

- **Name:** `volumes` (or `cinder-volumes` per kolla-ansible convention)
- **Type:** replicated
- **Size:** 3
- **Rule:** `replicated_ssd` (CRUSH rule with device class ssd, chooseleaf type host)
- **Use:** Cinder RBD backend for OpenStack block storage

```bash
ceph osd pool create volumes 64 64 replicated replicated_ssd
ceph osd pool application enable volumes rbd
```

## HDD pool (optional)

- **Name:** `hdd-pool`
- **Type:** replicated (or erasure-coded for space)
- **Size:** 3
- **Rule:** `replicated_hdd`
- **Use:** RGW, CephFS, or bulk storage later

```bash
ceph osd pool create hdd-pool 64 64 replicated replicated_hdd
# ceph osd pool application enable hdd-pool rgw  # when using RGW
```

## Prometheus metrics

Enable the mgr prometheus plugin so Prometheus can scrape Ceph metrics:

```bash
ceph mgr module enable prometheus
```

Metrics are served on the MGR HTTP port (default 9283).

# CRUSH rules for pilot

Use one OSD per disk; Ceph handles replication. Rule: **no two replicas on the same host** (`step chooseleaf type host`).

## Device classes

- **ssd:** 500G SSDs (use for volumes, images).
- **hdd:** 600G/900G/1.2T SATA (use for backups, vms, RGW).

## Create rules (after cluster bootstrap)

```bash
# Replicated size 3, one replica per host (host failure domain)
ceph osd crush rule create-replicated replicated_rule_ssd default host ssd
ceph osd crush rule create-replicated replicated_rule_hdd default host hdd
```

## Pool to rule mapping

- **volumes** (Cinder): `replicated_rule_ssd`, size 3.
- **images** (Glance): `replicated_rule_ssd`, size 3.
- **backups**: `replicated_rule_hdd`, size 3.
- **vms** (Nova ephemeral): `replicated_rule_hdd`, size 3.

Pools are defined in `pools.yaml`; apply rule names when creating pools (e.g. via cephadm or `ceph osd pool set <pool> crush_rule <rule_name>`).

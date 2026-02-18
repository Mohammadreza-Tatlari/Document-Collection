# CRUSH rules

## Device classes

After OSDs are created, set device class so pools can use them:

```bash
# List OSDs and set class (example: OSDs 0,1,2 are SSDs on node2,3,4)
ceph osd crush set-device-class ssd osd.0 osd.1 osd.2
ceph osd crush set-device-class hdd osd.3 osd.4 osd.5
```

## Replicated rule (host-level diversity)

Create a replicated rule that spreads replicas across hosts (required for size 3):

```bash
# SSD replicated rule – one replica per host
ceph osd crush rule create-replicated replicated_ssd default host ssd

# HDD replicated rule
ceph osd crush rule create-replicated replicated_hdd default host hdd
```

Use these rule names when creating pools (see `pools.md`).

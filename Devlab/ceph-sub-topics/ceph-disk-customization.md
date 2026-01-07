## How to Separate SSD and HDD Usage in Ceph
This is a CRUSH-level design tuning. If you don’t model SSD vs HDD explicitly in CRUSH, Ceph will never respect your intent—it will happily place RBD data on HDDs and backups on SSDs if the weights allow it. So the correct solution is: separate failure domains by device class and bind pools to rules. </br>
Ceph does not assign disks to pools directly. </br>
Pools → CRUSH rules → OSD selection.

Refrences:
- [CRUSH Maps on Ceph Docs (Mimic/Pacific/Latest)](https://docs.ceph.com/en/latest/rados/operations/crush-map-edits/?utm_source=chatgpt.com#manually-editing-the-crush-map)
- [Manually Editing a CRUSH MAP (Ceph Docs)](https://docs.ceph.com/en/latest/rados/operations/crush-map-edits/?utm_source=chatgpt.com#crush-map-rules)

### 1. Ensure OSDs are classified correctly (SSD vs HDD)
Modern Ceph (Luminous+) supports device classes automatically. but keep in mind that Ceph is blind to workload semantics unless you encode them in CRUSH.

1. check OSD Tree
- `ceph osd tree`

2. if HDD and SSD are not shown in tree list then it should be set manually: 
```sh
ceph osd crush set-device-class ssd osd.2
ceph osd crush set-device-class hdd osd.1
```

3. Verify it via:
```sh
ceph osd crush class ls
ceph osd crush class ls-osd ssd
ceph osd crush class ls-osd hdd
```


### 2. Create CRUSH rules per device class
You need at least two rules: One rule that selects only SSD OSDs, One rule that selects only HDD OSDs

1. Create SSD rule (for image / RBD pools)
- `ceph osd crush rule create-replicated ssd-only default host ssd`

2. Create HDD rule (for backup pools) 
- `ceph osd crush rule create-replicated hdd-only default host hdd`

3. check
- `ceph osd crush rule ls`

At this point, the placement logic is defined, but no pool uses it yet.


### 3. Create pools and bind them to rules

1. create and bind RBD pool on SSD
- `ceph osd pool create rbd-images 128`
- `ceph osd pool set rbd-images crush_rule ssd-only`

2. create and bind Backup pool on HDD
- `ceph osd pool create backups 256`
- `ceph osd pool set backups crush_rule hdd-only`

3. confirm them:
- `ceph osd pool get rbd-images crush_rule`
- `ceph osd pool get backups crush_rule`

RBD data → SSD OSDs only </br>
Backups → HDD OSDs only


## 6. Optional but strongly recommended: SSDs as DB/WAL for HDD OSDs
If your HDD OSDs are BlueStore (they should be), you can put **RocksDB/WAL on SSD** and Keep **data on HDD**. </br>
This improves HDD pool latency dramatically without mixing data.

Example with `ceph-volume`:
```bash
ceph-volume lvm create \
  --data /dev/sdb \
  --block-db /dev/nvme0n1p1 \
  --block-wal /dev/nvme0n1p2
```

This does **not** change placement rules — only performance.


## 7. Design sanity check (ask yourself)
Before deploying, answer these:

1. Can I lose *any* SSD OSD without impacting backup capacity?
2. Are SSDs sized for replica count + recovery IO?
3. Are backup pools allowed slower recovery (`osd_recovery_max_active`)?
4. Do I need erasure coding for backups instead of replication?

If you haven’t answered these, you’re still at a partial design level.


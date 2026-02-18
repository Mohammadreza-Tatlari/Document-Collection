# Runbook: Replace a failed or retired disk (Ceph OSD)

## Scope

Safely remove a Ceph OSD (failed or for replacement) and add a new OSD on the same or another node.

## Prerequisites

- Ceph cluster healthy (or degraded but quorum intact).
- New disk installed and visible to the OS (e.g. `lsblk`, `ceph orch device ls`).

## Steps

### 1. Remove the old OSD

```bash
# Identify OSD ID (e.g. from ceph osd tree or ceph -s)
ceph osd tree

# Mark OSD out (no new data)
ceph osd out <osd_id>

# Wait for rebalancing (optional; monitor with ceph -w)
# Then stop and destroy the OSD
ceph orch osd rm <osd_id> --replace  # if replacing with same device
# or
ceph orch osd rm <osd_id> --zap  # then add new device manually
```

### 2. Zap the old device (if reusing the same slot)

```bash
cephadm shell -- ceph orch device zap <hostname> <device> --force
```

### 3. Add the new OSD

**Option A – cephadm with device list**

```bash
cephadm shell -- ceph orch apply osd --all-available-devices
# or target specific host/device
cephadm shell -- ceph orch daemon add osd <hostname>:<device>
```

**Option B – OSD spec (this repo)**

- Update or add the node’s file in `ceph/osd-specs/` with the new device (and correct device_class: ssd/hdd).
- Apply: `cephadm shell -- ceph orch apply -i /path/to/spec.yaml` (path inside the container or mounted).

### 4. Verify

```bash
ceph -s
ceph osd tree
ceph health detail
```

### 5. Update documentation

- Update `docs/disk-map.md` with the new device serial, size, and node.

## Rollback

- If the new OSD causes issues, remove it with `ceph orch osd rm <osd_id>` and re-add after fixing the device or spec.
- Restore from replica if data was lost (Ceph recovers from replicas; ensure replication is 3 and no two replicas on same host).

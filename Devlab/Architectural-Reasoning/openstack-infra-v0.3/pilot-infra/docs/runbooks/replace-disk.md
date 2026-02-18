# Runbook: Replace a failed disk (Ceph OSD)

When a disk or OSD fails, replace the hardware and re-add the OSD.

## Prerequisites

- Replacement disk installed; same or larger size.
- OSD ID from `ceph osd tree` or `ceph -s`.

## Steps

1. **Mark OSD out (if not already out)**  
   ```bash
   ceph osd out osd.ID
   ```

2. **Stop and destroy the OSD**  
   ```bash
   ceph orch osd rm osd.ID --replace
   ```
   Or stop the daemon and zap the disk:
   ```bash
   ceph orch daemon stop osd.ID
   ceph-volume lvm zap /dev/sdX
   ```

3. **Replace the physical disk** (if not already done).

4. **Add the new OSD**  
   ```bash
   ceph orch device ls   # confirm new disk is available
   ceph orch daemon add osd HOSTNAME:/dev/sdX
   ```
   Set device class if needed:  
   `ceph osd crush set-device-class ssd osd.N` (or hdd).

5. **Verify**  
   ```bash
   ceph -s
   ceph osd tree
   ```
   Wait for PG state to be active+clean.

6. **Update** `docs/disk-map.md` with the new disk serial/device.

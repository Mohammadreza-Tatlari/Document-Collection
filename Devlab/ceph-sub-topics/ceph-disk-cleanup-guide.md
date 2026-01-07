### Ceph Disk Cleaning
If your goal is “return all former Ceph disks to completely clean raw disks”, you need to wipe three layers:
1. Ceph/LVM structures
2. Partition tables (GPT)
3. Filesystem signatures
Ceph doesn’t just create partitions or filesystems It embeds identity at multiple layers:
- GPT disk GUID
- LVM PV UUID
- Ceph OSD UUID
- filesystem signatures
Removing Ceph services alone never cleans disks. This is intentional to prevent accidental reuse.


1. Remove Ceph LVM metadata (important)
```sh
sudo lvs
sudo vgs
sudo pvs
```

2. Remove Ceph logical volumes
```sh
sudo lvremove -y /dev/ceph-*
```

3. Remove Ceph volume groups
```sh
sudo vgremove -y ceph-<id>
```
or
``` sh
for vg in $(sudo vgs --noheadings -o vg_name | grep 'ceph'); do
  sudo vgremove -y "$vg"
done
```

4. remove ceph physical volumes
```sh
sudo pvremove -y /dev/sdb /dev/sdc /dev/sdd /dev/sde
```

#### Zap GPT + partition tables (Ceph uses GPT)
Ceph creates GPT headers that survive LVM removal. GPT, backup GPT, Ceph disk GUIDs

```sh
sudo sgdisk --zap-all /dev/sdb
sudo sgdisk --zap-all /dev/sdc
sudo sgdisk --zap-all /dev/sdd
sudo sgdisk --zap-all /dev/sde
```


#### Remove filesystem signatures (wipefs)
Ceph leaves signatures that `lsblk` still detects.

```sh
sudo wipefs -a /dev/sdb
sudo wipefs -a /dev/sdc
sudo wipefs -a /dev/sdd
sudo wipefs -a /dev/sde
```


#### (Optional but recommended) Zero the first few MB
This guarantees nothing survives (fast, not a full wipe):

```sh
for d in sdb sdc sdd sde; do
  sudo dd if=/dev/zero of=/dev/$d bs=1M count=100 status=progress
done
```


#### Reload Kernel view
```sh
sudo partprobe
sudo udevadm settle
```

Verify Disk are clea:
```sh
lsblk
blkid
```


### Automated Format of the Above Steps:
it is possible to make the Ceph clean up process automated.
1. create a file with name `wiper.sh` and give executable permission:
- `vim wiper.sh` 
- `chmod +x 
2. edit the DISK array and change the disks carefully

```sh
#!/usr/bin/env bash
set -euo pipefail

# ===== CONFIG =====
# EDIT THIS LIST CAREFULLY
DISKS=(sdb sdc sdd sde)

# ==================

echo "=== Ceph disk cleanup starting ==="
echo "Target disks: ${DISKS[*]}"
echo

# ---- 1. Remove Ceph logical volumes ----
echo "[1/7] Removing Ceph logical volumes (if any)..."
lvs --noheadings -o lv_path 2>/dev/null | grep '^/dev/ceph' | while read -r lv; do
  echo "  Removing LV: $lv"
  lvremove -fy "$lv"
done || true

# ---- 2. Remove Ceph volume groups ----
echo "[2/7] Removing Ceph volume groups (if any)..."
vgs --noheadings -o vg_name 2>/dev/null | grep 'ceph' | while read -r vg; do
  echo "  Removing VG: $vg"
  vgremove -fy "$vg"
done || true

# ---- 3. Remove physical volumes ----
echo "[3/7] Removing LVM physical volumes..."
for d in "${DISKS[@]}"; do
  if pvs "/dev/$d" &>/dev/null; then
    echo "  pvremove /dev/$d"
    pvremove -fy "/dev/$d"
  else
    echo "  /dev/$d is not an LVM PV (skipping)"
  fi
done

# ---- 4. Zap GPT and partition tables ----
echo "[4/7] Zapping GPT and partition tables..."
for d in "${DISKS[@]}"; do
  echo "  sgdisk --zap-all /dev/$d"
  sgdisk --zap-all "/dev/$d"
done

# ---- 5. Remove filesystem signatures ----
echo "[5/7] Wiping filesystem signatures..."
for d in "${DISKS[@]}"; do
  echo "  wipefs -a /dev/$d"
  wipefs -a "/dev/$d"
done

# ---- 6. Zero first 100MB ----
echo "[6/7] Zeroing first 100MB of each disk..."
for d in "${DISKS[@]}"; do
  echo "  dd -> /dev/$d"
  dd if=/dev/zero of="/dev/$d" bs=1M count=100 status=progress
done

# ---- 7. Reload kernel disk state ----
echo "[7/7] Reloading kernel disk state..."
partprobe
udevadm settle

echo
echo "=== Cleanup complete ==="
echo "Final disk state:"
lsblk
```
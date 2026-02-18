# cephadm bootstrap and add-hosts

## Bootstrap (first node)

Run on the first Ceph node (e.g. node2, management IP 172.31.10.2):

```bash
# Install cephadm (Ubuntu 24.04)
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
chmod +x cephadm
sudo ./cephadm add-repo --release quincy
sudo ./cephadm install
sudo cephadm bootstrap --mon-ip 172.31.10.2
```

Use the Ceph cluster network (VLAN 111) if you want MON on storage network: e.g. `--mon-ip 172.31.11.2`. Bootstrap creates the first MON and MGR.

## Add remaining hosts

From the bootstrap node:

```bash
# Add node3..node6 (use management IPs for SSH, or Ceph IPs if reachable)
ceph orch host add node3 172.31.10.3
ceph orch host add node4 172.31.10.4
ceph orch host add node5 172.31.10.5
ceph orch host add node6 172.31.10.6
```

## Add OSDs

After adding hosts, add OSDs from designated disks (see disk-map and specs). Example:

```bash
# List available devices
ceph orch device ls

# Add all unused disks (then refine with device classes in CRUSH)
ceph orch daemon add osd node2:/dev/sdX
ceph orch daemon add osd node2:/dev/sdY
# ... repeat per node/disk
```

Or use a drive group spec (see `specs/osd-drivegroups.yaml`).

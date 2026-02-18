# Runbook: Failover and recovery (high-level)

High-level steps for common failure scenarios. See specific runbooks for details.

## Single compute node down

- **Ceph:** Remaining OSDs serve data (replication 3). No action required if PGs stay active; if a node is permanently lost, remove it from the cluster and replace OSDs (see [replace-disk.md](replace-disk.md)) or [add-compute-node.md](add-compute-node.md).
- **OpenStack:** Instances on that node are lost or suspended. Evacuate VMs if the node is temporarily down: `nova evacuate INSTANCE_ID` (target host optional). If the node is permanently lost, remove it from the inventory and redeploy compute on a new node.

## Control node (Proxmox or control VM) down

- **OpenStack API/Horizon:** Unavailable until control is restored. Restore from backup on a new control host (see [restore-openstack-db.md](restore-openstack-db.md)), or recover the VM/host.
- **Ceph:** Ceph MON/MGR may be on control or on compute nodes. If 2 of 3 MONs are up, cluster stays in quorum. Replace lost MON/MGR using cephadm if needed.
- **GitLab / Prometheus / Grafana:** Restore from backup or rebuild; config is in Git.

## Switch failure

- Single switch is a single point of failure. Document the switch config (see `network/switch-vlan-lacp.md`). For the larger cloud, plan a second switch (e.g. MCLAG) and redundant links.

## Full recovery (rebuild from Git)

1. Reinstall OS on all nodes (or use MAAS when introduced).
2. Apply network config (bond + VLANs) from `network/`.
3. Run Ansible base OS and users from `ansible/`.
4. Bootstrap Ceph and add OSDs per `ceph/`.
5. Deploy OpenStack with kolla-ansible per `openstack/`.
6. Restore OpenStack DB from last backup if needed.
7. Deploy monitoring from `monitoring/`.

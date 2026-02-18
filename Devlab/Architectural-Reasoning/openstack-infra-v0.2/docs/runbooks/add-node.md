# Runbook: Add a new node to the cluster

## Scope

Add a new bare-metal node (compute + Ceph OSD) to the existing OpenStack + Ceph pilot.

## Prerequisites

- Node is connected to the same switch, LACP and VLAN 110/111 configured on the switch.
- MAAS has been updated with the new machine (enlist, commission).
- IP plan: choose next free IP in 172.31.10.0/24 and 172.31.11.0/24.

## Steps

1. **MAAS**
   - Add machine in MAAS (or use existing if already enlisted).
   - Allocate the node; note the chosen IP or set static in MAAS.

2. **Autoinstall**
   - Copy `maas/autoinstall-compute-node.yaml` and set hostname, `172.31.10.X`, `172.31.11.X`, password hash, SSH key.
   - Deploy the machine from MAAS with this user-data (Ubuntu 24.04 LTS).

3. **Inventory**
   - Add the new host to `inventory/production/hosts.yml` under `compute`, `ceph-osd`, and optionally `network`.
   - Set `ansible_host` to the management IP (172.31.10.X).
   - Add to Ceph OSD placement in `ceph/cluster-spec.yaml` or cephadm host list if using dynamic placement.

4. **Ceph**
   - If using cephadm: add host to the cluster, then add OSDs (via osd-spec or `ceph orch apply osd`).
   - Create/update `ceph/osd-specs/<hostname>-osds.yaml` and apply.

5. **OpenStack**
   - Run kolla-ansible to add the new compute node:
     - `kolla-ansible -i inventory/production/hosts.yml deploy --limit compute` (or include the new host in a group and run deploy for that group).
   - Or run full deploy if your playbooks are idempotent and include the new host.

6. **Verification**
   - `nova hypervisor-list` shows the new node.
   - `ceph osd tree` shows new OSDs.
   - Run prechecks and smoke tests from the deployment guide.

## Rollback

- Decommission the node in MAAS; remove from inventory and re-run deploy to remove from OpenStack/Ceph if needed.
- Remove OSDs gracefully via Ceph before removing the host.

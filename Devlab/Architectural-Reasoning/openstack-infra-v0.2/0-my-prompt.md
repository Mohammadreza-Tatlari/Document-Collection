[2 tools called]


Exploring the repo and locating todos to implement.


[4 tools called]


Checking existing files and the plan's repo structure:


[6 tools called]


Checking monitoring, ansible, and GitLab CI:


[5 tools called]


Implementing the plan: marking the todo in progress and creating the required structure.


[21 tools called]


Fixing the dns-ntp playbook (remove NTP duplication) and fixing the template path.


[2 tools called]


Putting the template beside the playbook so the template path resolves.


[3 tools called]


Updating inventory to six nodes (172.31.10.x) and aligning with the plan:


[1 tool called]


Updating kolla globals for VLAN 110/111 and 172.31.10.x.


[3 tools called]


Adding Ceph CRUSH rules and updating the cluster spec for the current inventory.


[5 tools called]


Adding a failover runbook and updating GitLab CI to include the new directories.


[4 tools called]


Updating README and PROJECT_STRUCTURE to reflect the new layout and fixing the firewall playbook (remove optional `state: enabled` so it doesn't block).


[7 tools called]


Running playbook syntax check and fixing any issues:


[3 tools called]


Checking for lint issues and marking the todo complete.


[2 tools called]


Summary of what was implemented from the plan (without editing the plan file):

**1. Network (`network/`)**
- `README.md` – design (LACP, VLAN 110/111) and usage
- `templates/debian-bond-vlan110-vlan111.conf.j2` – Debian/ifupdown bond + VLAN 110/111
- `templates/netplan-bond-vlan110-vlan111.yaml.j2` – Netplan version for Ubuntu

**2. MAAS (`maas/`)**
- `README.md` – how to use templates and PXE (native VLAN 110)
- `autoinstall-control-node.yaml` – control node: bond, VLAN 110/111, 172.31.10.2, 172.31.11.2, storage on 500G
- `autoinstall-compute-node.yaml` – compute node: bond, VLAN 110/111, 172.31.10.3 / 172.31.11.3 (example), OS on first 500G, rest for Ceph

**3. Docs (`docs/`)**
- `adr/001-network-vlan-110-111.md` – ADR for two-VLAN design and PXE
- `runbooks/add-node.md` – add new compute node
- `runbooks/replace-disk.md` – replace Ceph OSD disk
- `runbooks/restore-openstack-db.md` – restore OpenStack DB (MariaDB/Galera)
- `runbooks/failover.md` – control/compute and single-switch failover
- `disk-map.md` – template table for disk serial/size/node and OSD mapping

**4. Monitoring (`monitoring/`)**
- `README.md` – overview
- `prometheus/prometheus.yml` – scrape node, Ceph, optional OpenStack (172.31.10.x)
- `prometheus/rules/alerts.yml` – NodeDown, HighCpu, LowDiskRoot, CephHealth
- `alertmanager/alertmanager.yml` – routing and placeholder receivers
- `grafana/dashboards/dashboard-pilot.json` – simple pilot overview (node up, CPU)

**5. Ansible (`ansible/`)**
- `playbooks/base-os.yml` – deploy user, SSH keys, chrony NTP, common packages
- `playbooks/templates/chrony.conf.j2` – Chrony template
- `playbooks/firewall.yml` – ufw rules for 172.31.10.0/24 and 172.31.11.0/24 (ufw enable commented for pilot)
- `playbooks/dns-ntp.yml` – systemd-resolved DNS from group_vars

**6. Inventory**
- `inventory/production/hosts.yml` – 6-node pilot: `node-01` (172.31.10.1), `controller-01` (172.31.10.2), `compute-01..05` (172.31.10.3–7); groups bootstrap, control, compute, ceph-mon, ceph-osd, network, storage, monitoring; interfaces `br0-v110` / `br0-v111`

**7. Kolla**
- `kolla/globals.yml` – network: VIPs 172.31.10.2 / 172.31.11.2, interfaces `br0-v110` / `br0-v111`
- `inventory/production/group_vars/all.yml` – management/public/storage interfaces and VIPs aligned with above

**8. Ceph**
- `ceph/cluster-spec.yaml` – MON on controller-01, compute-01, compute-02; MGR on controller-01, compute-01; duplicate dashboard MGR block removed
- `ceph/crush-rules.md` – CRUSH rules (replicated, host failure domain), device classes ssd/hdd, pool-to-rule mapping

**9. Repo and CI**
- `README.md` and `PROJECT_STRUCTURE.md` – 6-node layout, VLANs, network/maas/monitoring, docs/adr and docs/runbooks, disk-map
- `docs/architecture.md` – hardware and network updated to 6-node and VLAN 110/111
- `.gitlab-ci.yml` – yamllint extended to `network/`, `maas/`, `monitoring/`

**10. Optional**
- `ansible/templates/chrony.conf.j2` kept at repo root for reuse; playbook uses `playbooks/templates/chrony.conf.j2`.

Before first deploy: set `admin_ssh_keys` (and optionally `dns_servers` / `ntp_servers`) in `inventory/production/group_vars/all.yml`, generate and vault-encrypt `kolla/passwords.yml`, and fill `docs/disk-map.md` per node. Use MAAS autoinstall templates with hostname and IPs set per node (compute-02..05 use 172.31.10.4–7 and 172.31.11.4–7).
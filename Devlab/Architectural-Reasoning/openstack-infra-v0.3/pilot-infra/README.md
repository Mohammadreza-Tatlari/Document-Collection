# OpenStack + Ceph Pilot Infrastructure (No MAAS)

Production-grade IaC for the 6-node pilot: 1 Proxmox + 5 Ubuntu 24.04, OpenStack (kolla-ansible), Ceph (cephadm), three VLANs (110/111/112), GitLab CI/CD, Prometheus + Grafana.

## Repo layout

| Directory | Purpose |
|-----------|--------|
| `network/` | Switch config, LACP, VLANs; interface configs for Proxmox and Ubuntu |
| `ceph/` | cephadm spec, OSD layout, CRUSH rules, pool definitions |
| `openstack/` | kolla-ansible config (`globals.yml`), inventory |
| `ansible/` | Base OS playbooks (users, firewall, NTP, DNS) |
| `monitoring/` | Prometheus, Grafana, Alertmanager configs |
| `docs/` | ADRs, runbooks, disk map |

## Usage

- Use Ansible Vault or SOPS for secrets (`passwords.yml`, API keys); do not commit plain secrets.
- Tag releases (e.g. `pilot-v1`) for version control.
- Run Ansible and kolla-ansible from a deploy host with access to all nodes over VLAN 110.

## VLANs

- **110** (172.31.10.0/24): Management, API, SSH, GitLab, Horizon
- **111** (172.31.11.0/24): Ceph cluster
- **112** (172.31.12.0/24): Neutron tenant/data plane

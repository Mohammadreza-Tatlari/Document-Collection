# Network

Interface configs, VLANs, and LACP for the pilot. All 6 servers use a bond of 3 NICs with VLANs 110, 111, 112 tagged.

## VLANs

| VLAN | Subnet | Purpose |
|------|--------|---------|
| 110 | 172.31.10.0/24 | Management, API, SSH, GitLab, Prometheus/Grafana, Horizon |
| 111 | 172.31.11.0/24 | Ceph cluster (public/cluster) |
| 112 | 172.31.12.0/24 | Neutron tenant/data plane |

## Files

- `switch-vlan-lacp.md` – Switch configuration notes and snippet
- `ubuntu24/` – Netplan and bond+VLAN templates for Ubuntu 24.04
- `proxmox/` – Proxmox bridge/VLAN template

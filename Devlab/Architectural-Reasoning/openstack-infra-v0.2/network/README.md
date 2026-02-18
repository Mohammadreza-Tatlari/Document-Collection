# Network Configuration

Interface configs for the 6-node pilot: LACP bond (eno1+eno2+eno3), VLAN 110 (management), VLAN 111 (storage/tenant).

## Design

- **Bond0:** `eno1 + eno2 + eno3` in 802.3ad (LACP). On the switch: port-channel with VLAN 110 and 111 tagged; recommend VLAN 110 as native for PXE/MAAS.
- **VLAN 110 (172.31.10.0/24):** Management, API, MAAS, PXE, Horizon, SSH, GitLab, Prometheus/Grafana.
- **VLAN 111 (172.31.11.0/24):** Ceph cluster/public and/or Neutron tenant data plane.

## Usage

- `templates/` – Netplan/debian template; substitute `{{ management_ip }}`, `{{ gateway }}`, `{{ hostname }}`.
- Use with MAAS autoinstall (see `../maas/`) or manual deployment.
- Gateway: 172.31.10.254 (update if different).

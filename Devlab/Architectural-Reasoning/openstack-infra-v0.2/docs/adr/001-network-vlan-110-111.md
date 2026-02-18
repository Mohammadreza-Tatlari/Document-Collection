# ADR-001: Two-VLAN network design (110 management, 111 storage/tenant)

## Status

Accepted.

## Context

- 6x HP DL360 G8 servers, each with 3 NICs to a single LACP-capable switch.
- Need management, OpenStack API, MAAS, PXE, Ceph cluster, and optional tenant data plane on a single physical fabric.
- DL360 G8 PXE may not be VLAN-aware; DHCP must be reachable at boot.

## Decision

- **VLAN 110 (172.31.10.0/24):** Management, API, MAAS, PXE, Horizon, SSH, GitLab, Prometheus/Grafana.
- **VLAN 111 (172.31.11.0/24):** Ceph cluster/public and/or Neutron tenant data plane.
- Per-server: LACP bond (eno1+eno2+eno3), then `bond0.110` and `bond0.111` with bridges.
- On the switch: port-channel with VLAN 110 set as **native (untagged)** so PXE/DHCP works without NIC VLAN awareness at boot; VLAN 111 tagged.

## Consequences

- Single trunk per server; no separate provisioning NIC required.
- All post-install traffic uses tagged VLANs; autoinstall configures bond+VLANs so OS is VLAN-aware.
- If native VLAN cannot be used, a dedicated untagged provisioning VLAN or separate port is required for MAAS PXE.

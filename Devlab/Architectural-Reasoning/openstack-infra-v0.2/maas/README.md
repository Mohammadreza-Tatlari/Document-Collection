# MAAS Autoinstall Templates

Cloud-init autoinstall YAMLs for MAAS deployment: bond + VLAN 110/111, static IPs, disk layout.

## Usage

1. Replace placeholders in the template (or use per-host files):
   - `YOUR_PASSWORD_HASH` → `mkpasswd --method=SHA-512`
   - `YOUR_SSH_PUBLIC_KEY` → `cat ~/.ssh/id_ed25519.pub`
   - Hostname and IP per server (172.31.10.1 = bootstrap, 172.31.10.2–6 = compute-01..05 or control).
2. In MAAS: Deploy → choose Ubuntu 24.04 LTS → enable "Cloud-init user-data" → paste YAML.
3. Use **control** template for the OpenStack control node, **compute** for compute+Ceph nodes.

## Switch / PXE

- Set VLAN 110 as **native (untagged)** on server ports so PXE/DHCP works without VLAN awareness in BIOS.
- After install, the OS configures bond + `bond0.110` and `bond0.111` as in the template.

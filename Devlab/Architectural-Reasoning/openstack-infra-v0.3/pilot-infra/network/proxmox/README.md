# Proxmox bond + VLAN

Proxmox uses `/etc/network/interfaces` (Debian-style). Use the snippet in `interfaces-bond-vlans.conf.example` as reference. Create a bond over the 3 NICs, then Linux bridges (e.g. vmbr0 for VLAN 110, vmbr1 for 111, vmbr2 for 112) or VLAN-aware bridge as needed for VMs and host management.

Replace interface names (e.g. eno1, eno2, eno3) and IPs to match your node 1 (Proxmox).

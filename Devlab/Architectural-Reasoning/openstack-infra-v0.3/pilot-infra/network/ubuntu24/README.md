# Ubuntu 24.04 bond + VLAN

Use the template `netplan-bond-vlans.yaml.j2` with Ansible (or copy and substitute variables). Each node gets:

- Bond `bond0`: 802.3ad over eno1, eno2, eno3 (adjust interface names per node).
- VLAN sub-interfaces: bond0.110, bond0.111, bond0.112 with static IPs from the respective subnets.

Replace `NODE_ID`, `MANAGEMENT_IP`, `CEPH_IP`, `TENANT_IP`, and interface names per host.

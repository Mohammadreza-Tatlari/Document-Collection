# Runbook: Add a compute node

Use when adding a new Ubuntu 24.04 server as OpenStack compute and Ceph OSD.

## Prerequisites

- New host has bond + VLANs 110, 111, 112 configured (see `network/ubuntu24/`).
- Switch: port-channel with VLANs 110, 111, 112 tagged for the new server.
- Management IP assigned (e.g. 172.31.10.x), DNS and NTP applied.

## Steps

1. **Base OS (Ansible)**  
   Add the new host to `ansible/inventory/hosts.yml` under `ubuntu_compute`. Run:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/site-base-os.yml -l NEWHOST
   ansible-playbook -i inventory/hosts.yml playbooks/users-ssh-keys.yml -l NEWHOST
   ```

2. **Ceph**  
   From the bootstrap node:
   ```bash
   ceph orch host add NEWHOST MANAGEMENT_IP
   ceph orch daemon add osd NEWHOST:/dev/sdX   # for each disk (see disk-map)
   ```
   Set device class: `ceph osd crush set-device-class ssd osd.N` (or hdd).

3. **OpenStack (kolla-ansible)**  
   Add the new host to `openstack/inventory/multinode` under `[compute]`. Then:
   ```bash
   kolla-ansible -i inventory/multinode deploy --limit compute,NEWHOST
   ```
   Or run full deploy if your playbooks support it.

4. **Monitoring**  
   Install node_exporter on the new host and add its management IP:9100 to `monitoring/prometheus/prometheus.yml`. Reload Prometheus.

5. **Documentation**  
   Update `docs/disk-map.md` with the new node’s disks.

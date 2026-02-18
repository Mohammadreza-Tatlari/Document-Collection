Act as a DevOps and Cloud architecture expert. and give a solution for this design that I am going to introduce:

- there are 6 HP DL360 G8 servers that each have 3 interfaces to a switch and one of servers are being used as Proxmox Host. the other 5 servers are ubuntu 24.04 server
- all servers are connected to a switch and this switch can also make interfaces LACP as we need so.
- each server has mixture of SSD and HDD disk but the number of SSDs are 10 and all are 500GB and we have mixture of 900GB SATA and 1.2T SATA and 600GB SATA HDD Disk distributed across Servers.
- we have 3 vlans: vlan 110 that has the subnet of 172.31.10.0/24 and vlan 111 that has subnet of 172.31.11.0/24 and vlan 112 for 172.31.12.0/24
- the switch that all servers are connected to is Trunk and vlan 110 111 112 are inside this trunk. all 3 interfaces for all 3 servers are ether-channel (but we can change it if you think it is a better idea).
- I am using Proxmox Server for using services such as Canonical MAAS to provision my bare-metal servers and etc (but I don't want to use Metal as a Service Yet it will be a later additional project for my cloud so don't mention MAAS for this scenario until it is mentioned).
- all 6 servers have 1 ILO interface that are 172.26.1.101-106 and can be seen from vlan 110, 111, 112 as well
- our goal is to establish an infrastructure to reduce manual changes and be able to have version controling and automation. thus what implementation has come to our mind is openstack.
- we have plan to deploy openstack as orchestrator of our infrastructure and the software stack which will be used for metering and portal and our cloud OS.
- we have planned to use a Software Defined Storage to manage our Disk which we have come to Ceph as our implementation.
- this infra is going to be act as a pilot so we can have hands on cloud project and prepare our self for the bigger one that we are planning so its going to be used as a production grade material.
- it needs to be mention that we want to use kolla-ansible for openstack deployment, cephadm for ceph deployment. gitlab for CI/CD and version controling (we already have gitlab up and running so we don't need to install gitlab again) and we also want to use prometheus + grafana for monitoring.
now based on these steps and procedures I might have missed some parts that are used as practices in design level for devops.
can you give us an Architecture with Implementation as well? also create a walk through from phases that we need to take to establish our cloud infrastructure.




Summary of what’s in place:

---


**Implementation summary**

The plan is implemented under **`pilot-infra/`** (next to your plan and questioning files). All related todos are done. Here’s what’s there:

**Phase 1 – Foundation**  
- **Repo layout:** `network/`, `ceph/`, `openstack/`, `ansible/`, `monitoring/`, `docs/` with a root `README.md` and `.gitignore`.  
- **Network:**  
  - `network/switch-vlan-lacp.md` – switch LACP + VLAN 110/111/112 notes.  
  - `network/ubuntu24/` – Netplan bond+VLAN Jinja2 template and example inventory vars.  
  - `network/proxmox/` – example `/etc/network/interfaces` for bond+VLAN on Proxmox.  
- **Ansible:**  
  - `ansible/inventory/hosts.example.yml` and `group_vars/all.yml`.  
  - `playbooks/site-base-os.yml` (chrony, UFW, DNS), `users-ssh-keys.yml`, `deploy-netplan.yml`.  
  - `templates/chrony.conf.j2` and `netplan-bond-vlans.yaml.j2`.  
- **Docs:** `docs/disk-map.md`, `docs/ADRs/` (README + ADR-001 stack choices).

**Phase 2 – Ceph**  
- `ceph/README.md`, `cephadm-bootstrap.md`, `specs/cluster.yaml`, `specs/osd-drivegroups.yaml`, `crush-rules.md`, `pools.md`.

**Phase 3 – OpenStack**  
- `openstack/README.md`, `inventory/multinode`, `globals.yml` (VLANs, Cinder/Ceph, release), `passwords.yml.example`, `.gitignore` (ignores `passwords.yml`).

**Phase 4 – Automation and production-grade**  
- **GitLab CI:** `.gitlab-ci.yml` (yamllint, ansible-lint on MRs), `.yamllint`.  
- **Monitoring:** `monitoring/prometheus/prometheus.yml`, `monitoring/alertmanager/alertmanager.yml`, `monitoring/grafana/README.md`.  
- **Runbooks:** `docs/runbooks/` – add-compute-node, replace-disk, restore-openstack-db, failover.

**Next steps for you**  
1. Copy `ansible/inventory/hosts.example.yml` to `hosts.yml` and set real IPs/hostnames.  
2. Copy `openstack/passwords.yml.example` to `passwords.yml`, run `kolla-genpwd`, then encrypt with `ansible-vault encrypt passwords.yml`.  
3. Push `pilot-infra/` to your GitLab and run the pipeline (e.g. merge request) to confirm lint.  
4. Follow the phase order: network and switch, then Ansible base OS, then Ceph (cephadm), then OpenStack (kolla-ansible), then monitoring and runbooks as needed.
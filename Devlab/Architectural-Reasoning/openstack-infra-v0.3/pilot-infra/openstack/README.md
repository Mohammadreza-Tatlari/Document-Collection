# OpenStack (kolla-ansible)

kolla-ansible configuration and inventory for the pilot. Control plane runs on Proxmox VMs; compute on the 5 Ubuntu nodes. Cinder uses Ceph RBD (SSD pool).

## Layout

- `inventory/` – Multinode inventory (control vs compute)
- `globals.yml` – kolla-ansible globals (override defaults)
- `passwords.yml` – Encrypt with Ansible Vault; do not commit plain secrets

## Usage

```bash
# From a deploy host with kolla-ansible installed
kolla-ansible -i inventory/multinode bootstrap-servers
kolla-ansible -i inventory/multinode prechecks
kolla-ansible -i inventory/multinode deploy
```

See [kolla-ansible docs](https://docs.openstack.org/kolla-ansible/latest/).

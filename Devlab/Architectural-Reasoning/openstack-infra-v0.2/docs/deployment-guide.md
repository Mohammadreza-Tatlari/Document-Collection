# Deployment Guide

This guide walks through the step-by-step process of deploying OpenStack with Ceph.

## Prerequisites

### Deploy-Node Requirements

- Ubuntu 20.04 or 22.04 (or CentOS 8/9)
- Python 3.8+
- Ansible >= 2.9
- Kolla-Ansible installed
- Cephadm installed
- GitLab Runner installed and registered
- SSH access to all cluster nodes

### Cluster Node Requirements

- Ubuntu 20.04 or 22.04 (or CentOS 8/9)
- Minimum 32GB RAM per node
- Minimum 2 network interfaces
- SSH access configured
- Passwordless sudo for deploy user

## Initial Setup

### 1. Clone Repository

```bash
git clone git@gitlab.example.com:openstack/openstack-infra.git
cd openstack-infra
```

### 2. Configure Inventory

Edit `inventory/production/hosts.yml`:

1. Update hostnames
2. Update IP addresses
3. Update network interfaces
4. Verify group assignments

### 3. Configure Global Variables

Edit `inventory/production/group_vars/all.yml`:

1. Set `openstack_release` (e.g., "yoga", "zed")
2. Set `kolla_internal_vip_address`
3. Set `kolla_external_vip_address`
4. Update network interfaces

### 4. Configure Kolla-Ansible

Edit `kolla/globals.yml`:

1. Verify `openstack_release`
2. Update network interfaces
3. Configure service enablement
4. Set Ceph integration parameters

### 5. Encrypt Passwords

```bash
# Generate passwords.yml if not exists
cp kolla/passwords.yml.template kolla/passwords.yml

# Edit and set passwords
ansible-vault edit kolla/passwords.yml

# Set vault password file (optional)
echo "your-vault-password" > .vault_pass.txt
chmod 600 .vault_pass.txt
```

### 6. Configure Ceph

Edit `ceph/cluster-spec.yaml`:

1. Update hostnames
2. Configure MON placement
3. Configure MGR placement

Create OSD specs in `ceph/osd-specs/`:

1. Create one file per node
2. Define SSD vs HDD devices
3. Set device classes

## Deployment Steps

### Phase 1: Ceph Deployment

1. **Bootstrap Ceph Cluster**

   ```bash
   # On deploy-node
   cephadm bootstrap --mon-ip <first-mon-ip> \
     --cluster-network <storage-network> \
     --allow-fqdn-hostname
   ```

2. **Add Hosts to Cluster**

   ```bash
   cephadm shell -- ceph orch host add <hostname> <ip>
   ```

3. **Apply Cluster Spec**

   ```bash
   cephadm shell -- ceph orch apply -i ceph/cluster-spec.yaml
   ```

4. **Create OSDs**

   ```bash
   # For each node
   cephadm shell -- ceph orch apply osd -i ceph/osd-specs/<node>-osds.yaml
   ```

5. **Create Storage Pools**

   ```bash
   # Apply pools.yaml configuration
   ./scripts/deploy/ceph-create-pools.sh
   ```

6. **Create Ceph Client Keys**

   ```bash
   # Create keys for OpenStack services
   cephadm shell -- ceph auth get-or-create client.cinder \
     mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes'
   
   cephadm shell -- ceph auth get-or-create client.glance \
     mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
   
   cephadm shell -- ceph auth get-or-create client.nova \
     mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=vms'
   ```

7. **Distribute Client Keys**

   ```bash
   # Copy keys to all nodes
   ansible-playbook -i inventory/production/hosts.yml \
     ansible/playbooks/distribute-ceph-keys.yml
   ```

### Phase 2: OpenStack Deployment

1. **Run Prechecks**

   ```bash
   kolla-ansible -i inventory/production/hosts.yml prechecks
   ```

2. **Pull Container Images**

   ```bash
   kolla-ansible -i inventory/production/hosts.yml pull
   ```

3. **Deploy OpenStack**

   ```bash
   kolla-ansible -i inventory/production/hosts.yml deploy
   ```

4. **Post-Deploy Configuration**

   ```bash
   kolla-ansible -i inventory/production/hosts.yml post-deploy
   ```

5. **Verify Deployment**

   ```bash
   # Source admin credentials
   source /etc/kolla/admin-openrc.sh

   # Check services
   openstack service list
   openstack endpoint list

   # Check compute nodes
   openstack hypervisor list

   # Check networks
   openstack network list
   ```

## GitLab CI/CD Deployment

### Manual Deployment via Pipeline

1. **Merge Changes to Main**

   - Create feature branch
   - Make changes
   - Create merge request
   - Get approvals
   - Merge to `main`

2. **Tag Release** (optional)

   ```bash
   git tag -a openstack-1.0.0 -m "Initial deployment"
   git push origin openstack-1.0.0
   ```

3. **Trigger Deployment**

   - Go to GitLab CI/CD → Pipelines
   - Click on pipeline for `main` branch or tag
   - Manually trigger deployment jobs:
     - `deploy:ceph` (if Ceph changes)
     - `deploy:openstack-prechecks`
     - `deploy:openstack-pull`
     - `deploy:openstack-deploy`
     - `deploy:openstack-postdeploy`

## Post-Deployment

### Initial Configuration

1. **Create Admin User** (if not using default)

   ```bash
   source /etc/kolla/admin-openrc.sh
   openstack user create --password <password> admin
   openstack role add --user admin --project admin admin
   ```

2. **Create External Network**

   ```bash
   openstack network create --external --provider-physical-network physnet1 \
     --provider-network-type flat public
   openstack subnet create --network public --allocation-pool \
     start=192.168.1.200,end=192.168.1.250 \
     --gateway 192.168.1.1 --subnet-range 192.168.1.0/24 public-subnet
   ```

3. **Create Router**

   ```bash
   openstack router create router1
   openstack router set --external-gateway public router1
   ```

4. **Upload Test Image**

   ```bash
   wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
   openstack image create --disk-format qcow2 --container-format bare \
     --file focal-server-cloudimg-amd64.img ubuntu-20.04
   ```

### Verification

1. **Check Service Status**

   ```bash
   docker ps | grep -E "nova|neutron|cinder|glance|keystone"
   ```

2. **Check Ceph Status**

   ```bash
   cephadm shell -- ceph -s
   cephadm shell -- ceph osd tree
   ```

3. **Test VM Creation**

   ```bash
   # Create test network
   openstack network create test-net
   openstack subnet create --network test-net --subnet-range 10.0.0.0/24 test-subnet

   # Create test VM
   openstack server create --image ubuntu-20.04 --flavor m1.small \
     --network test-net test-vm
   ```

## Troubleshooting

See `docs/troubleshooting.md` for common issues and solutions.

## Rollback Procedures

### Rollback OpenStack Deployment

```bash
# Rollback to previous Kolla-Ansible deployment
kolla-ansible -i inventory/production/hosts.yml deploy --tags <service>
```

### Rollback Ceph Changes

```bash
# Ceph changes are typically non-destructive
# Review ceph/cluster-spec.yaml and reapply if needed
cephadm shell -- ceph orch apply -i ceph/cluster-spec.yaml
```

## Next Steps

- Configure monitoring and alerting
- Set up backup procedures
- Document operational procedures
- Train team members

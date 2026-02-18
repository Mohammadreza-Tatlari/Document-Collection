# Quick Start Guide

This guide helps you get started quickly with the OpenStack infrastructure project.

## 🚀 First Steps

### 1. Create GitLab Project

1. **Log into GitLab** and create a new project:
   - Project name: `openstack-infra`
   - Visibility: Private (recommended)
   - Initialize with README: No (we already have one)

2. **Push this repository** to GitLab:

   ```bash
   cd openstack-infra
   git init
   git remote add origin git@gitlab.example.com:openstack/openstack-infra.git
   git add .
   git commit -m "Initial commit: OpenStack infrastructure as code"
   git push -u origin main
   ```

### 2. Configure GitLab Project Settings

1. **Protect Main Branch**:
   - Settings → Repository → Protected Branches
   - Protect `main` branch
   - Allowed to merge: Maintainers
   - Allowed to push: No one

2. **Configure CI/CD Variables**:
   - Settings → CI/CD → Variables
   - Add these variables (mark as protected/masked):
     - `ANSIBLE_VAULT_PASSWORD`: Your ansible-vault password
     - `SSH_PRIVATE_KEY`: SSH private key for deploy-node (if needed)

3. **Set up CODEOWNERS**:
   - The CODEOWNERS file is already created
   - Update it with actual GitLab usernames once teams are assigned

### 3. Set Up Deploy-Node

1. **Install Prerequisites**:

   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install -y python3-pip ansible git
   pip3 install kolla-ansible
   
   # Install cephadm
   curl --silent --remote-name --location \
     https://github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm
   chmod +x cephadm
   sudo mv cephadm /usr/local/bin/
   ```

2. **Install GitLab Runner**:

   ```bash
   # Download and install GitLab Runner
   curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
   sudo apt-get install gitlab-runner
   
   # Register runner (get token from GitLab: Settings → CI/CD → Runners)
   sudo gitlab-runner register
   # Use shell executor
   # Tag: deploy-node
   ```

3. **Configure SSH Access**:

   ```bash
   # Generate SSH key if not exists
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "deploy-node"
   
   # Copy public key to all cluster nodes
   for host in server1 server2 server3 server4 server5; do
     ssh-copy-id -i ~/.ssh/id_ed25519.pub deploy@$host
   done
   ```

4. **Clone Repository**:

   ```bash
   git clone git@gitlab.example.com:openstack/openstack-infra.git
   cd openstack-infra
   ```

### 4. Configure Inventory

1. **Edit `inventory/production/hosts.yml`**:
   - Update hostnames
   - Update IP addresses
   - Update network interfaces

2. **Edit `inventory/production/group_vars/all.yml`**:
   - Set `openstack_release` (e.g., "yoga", "zed")
   - Set VIP addresses
   - Update network configuration

### 5. Configure Kolla-Ansible

1. **Edit `kolla/globals.yml`**:
   - Verify `openstack_release` matches your choice
   - Update network interfaces
   - Configure service enablement

2. **Set Up Passwords**:

   ```bash
   # Generate passwords
   ./scripts/utils/generate-passwords.sh > passwords.txt
   
   # Edit passwords.yml with generated passwords
   ansible-vault edit kolla/passwords.yml
   
   # Or create from template
   cp kolla/passwords.yml kolla/passwords.yml.backup
   # Edit passwords.yml with your passwords
   ansible-vault encrypt kolla/passwords.yml
   ```

### 6. Configure Ceph

1. **Edit `ceph/cluster-spec.yaml`**:
   - Update hostnames
   - Configure MON/MGR placement

2. **Create OSD Specs**:
   - Create files in `ceph/osd-specs/` for each node
   - Define SSD vs HDD devices
   - See `ceph/osd-specs/README.md` for examples

### 7. Test Pipeline

1. **Push Changes**:

   ```bash
   git add .
   git commit -m "Configure inventory and settings"
   git push origin main
   ```

2. **Check Pipeline**:
   - Go to GitLab → CI/CD → Pipelines
   - Verify lint and validate jobs pass

### 8. First Deployment

⚠️ **Important**: Review all configurations before deploying!

1. **Validate Configuration**:

   ```bash
   # Run prechecks
   ./scripts/validate/prechecks.sh
   
   # Validate Ceph config
   ./scripts/deploy/ceph-deploy.sh --dry-run
   ```

2. **Deploy Ceph** (via GitLab CI/CD):
   - Go to CI/CD → Pipelines
   - Click on latest pipeline
   - Manually trigger `deploy:ceph`

3. **Deploy OpenStack** (via GitLab CI/CD):
   - Manually trigger deployment jobs in order:
     - `deploy:openstack-prechecks`
     - `deploy:openstack-pull`
     - `deploy:openstack-deploy`
     - `deploy:openstack-postdeploy`

## 📋 Pre-Deployment Checklist

- [ ] All hostnames and IPs updated in inventory
- [ ] Network interfaces configured correctly
- [ ] OpenStack release selected and consistent
- [ ] Passwords generated and encrypted
- [ ] Ceph cluster spec configured
- [ ] OSD specs created for all nodes
- [ ] SSH access tested to all nodes
- [ ] GitLab Runner installed and registered
- [ ] CI/CD variables configured
- [ ] Main branch protected
- [ ] Team members added to GitLab project

## 🔍 Verification

After deployment, verify:

```bash
# Source admin credentials
source /etc/kolla/admin-openrc.sh

# Check services
openstack service list
openstack endpoint list
openstack hypervisor list

# Check Ceph
cephadm shell -- ceph -s
cephadm shell -- ceph osd tree
```

## 📚 Next Steps

1. **Read Documentation**:
   - `docs/architecture.md` - Architecture overview
   - `docs/deployment-guide.md` - Detailed deployment steps
   - `docs/team-workflow.md` - How to work with the team
   - `docs/troubleshooting.md` - Common issues

2. **Assign Teams**:
   - Update CODEOWNERS with actual team assignments
   - Define component ownership

3. **Set Up Monitoring**:
   - Configure Prometheus/Grafana
   - Set up alerts

4. **Create Staging Environment** (optional):
   - Copy `inventory/production` to `inventory/staging`
   - Configure staging-specific settings

## 🆘 Getting Help

- **Documentation**: Check `docs/` directory
- **Issues**: Create GitLab issues
- **Questions**: Ask in GitLab Discussions
- **Emergency**: Contact senior engineer

## ⚠️ Important Notes

- **Never commit unencrypted passwords**
- **Always test in staging first** (if available)
- **Review all changes via merge requests**
- **Tag releases** for tracking
- **Backup configurations** regularly

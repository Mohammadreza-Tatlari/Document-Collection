# OpenStack Infrastructure as Code

This repository contains all configuration, deployment scripts, and infrastructure definitions for our OpenStack cloud deployment using Kolla-Ansible and Ceph.

## 🏗️ Architecture Overview

- **OpenStack Deployment**: Kolla-Ansible (containerized OpenStack services)
- **Storage Backend**: Ceph (deployed via cephadm)
- **Hardware**: 6x HP DL360 G8 (1 Proxmox/Bootstrap + 5 compute+Ceph; control on VM or dedicated)
- **Network**: VLAN 110 (172.31.10.0/24) management, VLAN 111 (172.31.11.0/24) storage/tenant, LACP bond
- **Deployment Method**: GitLab CI/CD, MAAS bare-metal, Kolla-Ansible, cephadm

## 📁 Repository Structure

```
openstack-infra/
├── .gitlab-ci.yml          # CI/CD pipeline definitions
├── CODEOWNERS              # Code ownership and review requirements
├── README.md               # This file
├── docs/                   # Documentation
│   ├── architecture.md     # Architecture decisions and diagrams
│   ├── deployment-guide.md # Step-by-step deployment procedures
│   ├── team-workflow.md    # How teams collaborate
│   ├── troubleshooting.md  # Common issues and solutions
│   ├── disk-map.md         # Disk serial/size/node and OSD mapping
│   ├── adr/                # Architecture decision records
│   └── runbooks/           # Add node, replace disk, restore DB, failover
├── network/                # Network config (LACP, VLAN 110/111)
│   └── templates/          # Debian/Netplan interface templates
├── maas/                   # MAAS autoinstall (control + compute, VLAN 110/111)
├── inventory/              # Ansible inventory files
│   └── production/         # 6-node pilot hosts and group_vars
├── kolla/                  # Kolla-Ansible configuration
│   ├── globals.yml         # Global OpenStack (VLAN 110/111, Ceph)
│   ├── passwords.yml       # Encrypted passwords (ansible-vault)
│   └── config/             # Service-specific overrides
├── ceph/                   # Ceph (cephadm) configuration
│   ├── cluster-spec.yaml   # MON/MGR/OSD placement
│   ├── pools.yaml          # SSD/HDD pool definitions
│   ├── crush-rules.md      # CRUSH rules (replicated, host failure domain)
│   └── osd-specs/          # OSD specs per node
├── scripts/                # Deployment and utility scripts
├── ansible/                # Custom Ansible playbooks
│   ├── playbooks/          # base-os, firewall, dns-ntp, distribute-ceph-keys
│   └── templates/
├── monitoring/             # Prometheus, Grafana, Alertmanager configs
│   ├── prometheus/
│   ├── alertmanager/
│   └── grafana/dashboards/
└── .gitignore              # Git ignore patterns
```

## 👥 Team Organization

- **1 Senior Engineer**: Architecture decisions, code reviews, critical deployments
- **3 Mid-Level Engineers**: Component ownership, mentoring juniors
- **6 Junior Engineers**: Feature development, testing, documentation

### Component Ownership (To Be Defined)

Teams will be assigned to manage:
- **Compute (Nova)**: VM lifecycle, scheduling, live migration
- **Networking (Neutron)**: Network provisioning, security groups, load balancers
- **Storage (Cinder/Glance)**: Block storage, image management
- **Identity (Keystone)**: Authentication, authorization, service catalog
- **Ceph Storage**: Cluster management, pool configuration, performance tuning

## 🚀 Getting Started

### Prerequisites

- Access to GitLab repository
- SSH access to deploy-node
- Ansible >= 2.9
- Kolla-Ansible installed on deploy-node
- Cephadm installed on deploy-node

### Initial Setup

1. Clone the repository:
   ```bash
   git clone git@gitlab.example.com:openstack/openstack-infra.git
   cd openstack-infra
   ```

2. Review the [deployment guide](docs/deployment-guide.md)

3. Configure your local environment (see `docs/team-workflow.md`)

## 🔄 Workflow

1. **Create Feature Branch**: `git checkout -b feature/your-feature-name`
2. **Make Changes**: Edit configuration files in appropriate directories
3. **Commit & Push**: `git commit -am "Description" && git push origin feature/your-feature-name`
4. **Create Merge Request**: Open MR in GitLab, assign reviewers
5. **CI Pipeline Runs**: Automatic validation and linting
6. **Code Review**: Team members review and approve
7. **Merge**: Merge to `main` branch
8. **Deploy**: Manual deployment via GitLab CI/CD (protected branches only)

## 🔐 Security

- **Secrets Management**: All passwords stored in `kolla/passwords.yml` (ansible-vault encrypted)
- **SSH Keys**: Managed via GitLab CI/CD variables (protected/masked)
- **Access Control**: CODEOWNERS file enforces review requirements

## 📝 Versioning

- **Tags**: Use semantic versioning (e.g., `openstack-1.0.0`)
- **Branches**: 
  - `main`: Production-ready code
  - `develop`: Integration branch (optional)
  - `feature/*`: Feature branches

## 🆘 Support

- **Documentation**: Check `docs/` directory
- **Issues**: Create GitLab issues for bugs or feature requests
- **Questions**: Contact senior engineer or team leads

## 📚 Additional Resources

- [Kolla-Ansible Documentation](https://docs.openstack.org/kolla-ansible/)
- [Ceph Documentation](https://docs.ceph.com/)
- [OpenStack Documentation](https://docs.openstack.org/)

# Project Structure

Complete file tree and organization of the OpenStack Infrastructure repository.

```
openstack-infra/
│
├── .gitlab-ci.yml              # GitLab CI/CD pipeline definition
├── .gitignore                  # Git ignore patterns
├── CODEOWNERS                  # Code ownership and review requirements
├── README.md                   # Main project documentation
├── QUICKSTART.md              # Quick start guide
├── PROJECT_STRUCTURE.md        # This file
│
├── docs/                       # Documentation
│   ├── architecture.md         # Architecture decisions and diagrams
│   ├── deployment-guide.md     # Step-by-step deployment procedures
│   ├── team-workflow.md        # Team collaboration guide
│   ├── troubleshooting.md      # Common issues and solutions
│   ├── disk-map.md             # Disk serial/size/node and OSD mapping
│   ├── adr/                    # Architecture decision records
│   └── runbooks/               # add-node, replace-disk, restore-openstack-db, failover
│
├── network/                    # Network config (LACP, VLAN 110/111)
│   └── templates/              # Debian and Netplan interface templates
│
├── maas/                       # MAAS autoinstall YAMLs
│   ├── autoinstall-control-node.yaml
│   └── autoinstall-compute-node.yaml
│
├── inventory/                  # Ansible inventory files
│   └── production/             # Production environment
│       ├── hosts.yml           # Host definitions (5x HP DL360 G8)
│       └── group_vars/         # Group-specific variables
│           ├── all.yml         # Global variables
│           ├── controllers.yml # Control plane variables
│           ├── computes.yml    # Compute node variables
│           ├── storage.yml     # Storage node variables
│           └── ceph.yml        # Ceph cluster variables
│
├── kolla/                      # Kolla-Ansible configuration
│   ├── globals.yml             # Global OpenStack configuration
│   ├── passwords.yml           # Encrypted passwords (ansible-vault)
│   ├── multinode               # Multi-node inventory template (optional)
│   └── config/                 # Service-specific overrides
│       ├── nova.conf           # Nova compute configuration
│       ├── neutron.conf        # Neutron networking configuration
│       ├── cinder.conf         # Cinder block storage configuration
│       ├── glance-api.conf     # Glance image service configuration
│       └── keystone.conf       # Keystone identity configuration (if needed)
│
├── ceph/                       # Ceph cluster configuration
│   ├── cluster-spec.yaml       # Cephadm cluster specification
│   ├── pools.yaml              # Ceph pool definitions (SSD/HDD)
│   └── osd-specs/              # OSD specifications per node
│       ├── README.md           # OSD spec documentation
│       ├── compute-01-osds.yaml # TODO: Create per node
│       ├── compute-02-osds.yaml # TODO: Create per node
│       ├── compute-03-osds.yaml # TODO: Create per node
│       ├── compute-04-osds.yaml # TODO: Create per node
│       └── compute-05-osds.yaml # TODO: Create per node
│
├── scripts/                    # Deployment and utility scripts
│   ├── bootstrap/              # Bootstrap scripts (future)
│   ├── deploy/                 # Deployment orchestration
│   │   ├── ceph-deploy.sh      # Ceph deployment script
│   │   └── openstack-deploy.sh # OpenStack deployment script
│   ├── validate/               # Validation and prechecks
│   │   └── prechecks.sh        # Pre-deployment validation
│   └── utils/                  # Utility scripts
│       ├── generate-passwords.sh # Password generation
│       └── backup-config.sh    # Configuration backup
│
├── ansible/                    # Custom Ansible playbooks and roles
│   ├── playbooks/
│   │   └── distribute-ceph-keys.yml # Distribute Ceph keys to nodes
│   └── roles/                  # Custom roles (future)
│
└── monitoring/                 # Monitoring and alerting configs
    ├── prometheus/             # prometheus.yml, rules/alerts.yml
    ├── alertmanager/           # alertmanager.yml
    └── grafana/dashboards/     # dashboard-pilot.json
```

## Key Files Explained

### Configuration Files

- **`.gitlab-ci.yml`**: Defines CI/CD pipeline stages (lint, validate, deploy)
- **`CODEOWNERS`**: Enforces code review requirements by file/directory
- **`inventory/production/hosts.yml`**: Defines all 5 HP DL360 G8 servers
- **`kolla/globals.yml`**: Main OpenStack configuration via Kolla-Ansible
- **`kolla/passwords.yml`**: Encrypted service passwords (ansible-vault)
- **`ceph/cluster-spec.yaml`**: Ceph cluster topology (MON, MGR, OSD placement)
- **`ceph/pools.yaml`**: Storage pool definitions (SSD vs HDD pools)

### Deployment Scripts

- **`scripts/deploy/ceph-deploy.sh`**: Bootstrap and deploy Ceph cluster
- **`scripts/deploy/openstack-deploy.sh`**: Deploy OpenStack services
- **`scripts/validate/prechecks.sh`**: Pre-deployment validation

### Documentation

- **`README.md`**: Project overview and getting started
- **`QUICKSTART.md`**: Step-by-step setup guide
- **`docs/architecture.md`**: Architecture decisions and design
- **`docs/deployment-guide.md`**: Detailed deployment procedures
- **`docs/team-workflow.md`**: Team collaboration workflow
- **`docs/troubleshooting.md`**: Common issues and solutions

## Directory Purposes

### `inventory/`
Ansible inventory files defining hosts and groups. Separate directories for different environments (production, staging).

### `kolla/`
Kolla-Ansible configuration files. `globals.yml` is the main config, `config/` contains service-specific overrides.

### `ceph/`
Ceph cluster configuration managed by cephadm. `cluster-spec.yaml` defines services, `pools.yaml` defines storage pools.

### `scripts/`
Reusable scripts for deployment, validation, and utilities. Organized by purpose (deploy, validate, utils).

### `ansible/`
Custom Ansible playbooks and roles beyond Kolla-Ansible. Used for tasks like distributing Ceph keys.

### `docs/`
Project documentation covering architecture, deployment, workflows, and troubleshooting.

## File Naming Conventions

- **YAML files**: `.yml` or `.yaml` (consistent within directories)
- **Scripts**: `.sh` with descriptive names
- **Documentation**: `.md` (Markdown)
- **Configs**: Service name + `.conf` (e.g., `nova.conf`)

## TODO Items

Before first deployment, complete:

1. **Inventory**: Update all IPs, hostnames, interfaces in `inventory/production/hosts.yml`
2. **OSD Specs**: Create `ceph/osd-specs/*-osds.yaml` for each of the 5 nodes
3. **Passwords**: Generate and encrypt passwords in `kolla/passwords.yml`
4. **CODEOWNERS**: Update with actual GitLab usernames once teams are assigned
5. **Network Config**: Update network interfaces in `kolla/globals.yml` and `inventory/production/group_vars/all.yml`

## Future Additions

- `monitoring/prometheus/`: Prometheus configuration
- `monitoring/grafana/`: Grafana dashboards
- `ansible/roles/`: Custom Ansible roles
- `inventory/staging/`: Staging environment configuration
- `scripts/bootstrap/`: Bootstrap scripts for initial node setup

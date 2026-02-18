# Architecture Documentation

## Overview

This document describes the architecture of the OpenStack cloud infrastructure.

## Hardware

- **6x HP DL360 G8 servers**: 1 Proxmox/Bootstrap (node-01), 5 compute+Ceph (compute-01..05); OpenStack control on VM at 172.31.10.2 or on node-01
- **Deploy-node**: Proxmox host (node-01) or separate management node

## Network Architecture

### Network Segments (VLAN 110 / 111)

1. **Management** – VLAN 110 (`172.31.10.0/24`)
   - Used for: SSH, API, MAAS, PXE, Horizon, GitLab, Prometheus/Grafana
   - Interface: `br0-v110` (bridge over bond0.110)
   - LACP bond: eno1+eno2+eno3; VLAN 110 as native on switch for PXE

2. **Storage / Tenant** – VLAN 111 (`172.31.11.0/24`)
   - Used for: Ceph cluster and Neutron tenant data plane
   - Interface: `br0-v111` (bridge over bond0.111)

### High Availability (pilot)

- **Control Plane**: Single control node (controller-01) for pilot; scale to 3 for production HA
- **VIP / API**: Internal 172.31.10.2, External 172.31.11.2

## OpenStack Services

### Core Services (Essential)

1. **Keystone** (Identity)
   - Authentication and authorization
   - Service catalog

2. **Nova** (Compute)
   - VM lifecycle management
   - Scheduler
   - Hypervisor management

3. **Neutron** (Networking)
   - Network provisioning
   - Security groups
   - Load balancers (if Octavia enabled)

4. **Glance** (Image Service)
   - VM image storage
   - Backend: Ceph RBD

5. **Cinder** (Block Storage)
   - Volume management
   - Backend: Ceph RBD

6. **Horizon** (Dashboard)
   - Web UI for OpenStack

### Optional Services (Future)

- Heat (Orchestration)
- Octavia (Load Balancer)
- Magnum (Container Orchestration)
- Barbican (Key Management)

## Ceph Storage Architecture

### Cluster Topology

- **Monitors (MON)**: 3 nodes (controller-01, compute-01, compute-02)
- **Managers (MGR)**: 2 nodes (controller-01, compute-01)
- **OSDs**: All 5 compute nodes (compute-01..05); device classes ssd/hdd per `ceph/crush-rules.md`

### Storage Pools

#### Fast Pools (SSD-backed)
- **volumes**: Cinder block storage
- **images**: Glance image storage

#### Slow Pools (HDD-backed)
- **backups**: Cinder backup storage
- **vms**: Nova ephemeral storage (optional)

### Device Classes

- **SSD**: Fast storage for volumes and images
- **HDD**: Slow storage for backups and VM ephemeral disks

## Deployment Architecture

### Deploy-Node

- Runs GitLab Runner
- Executes Kolla-Ansible playbooks
- Executes Cephadm commands
- Manages SSH keys to all cluster nodes

### Deployment Flow

1. **Bootstrap Ceph** (via cephadm)
2. **Create Ceph Pools** (volumes, images, backups, vms)
3. **Create Ceph Client Keys** (cinder, glance, nova)
4. **Deploy OpenStack** (via kolla-ansible)
   - Prechecks
   - Pull container images
   - Deploy services
   - Post-deploy configuration

## Security Architecture

### Access Control

- **SSH**: Key-based authentication from deploy-node
- **OpenStack API**: Keystone authentication
- **Ceph**: Client key authentication

### Secrets Management

- All passwords encrypted with Ansible Vault
- SSH keys managed via GitLab CI/CD variables
- Ceph client keys stored encrypted

## Monitoring Architecture

- **Prometheus**: Metrics collection
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing (future)

## High Availability Strategy

### Control Plane HA

- 3-node Galera cluster (MariaDB)
- 3-node RabbitMQ cluster
- Keepalived + HAProxy for VIP management

### Compute HA

- Multiple compute nodes
- VM live migration between nodes

### Storage HA

- Ceph replication (3 replicas)
- Multiple OSDs per node
- Multiple MON nodes

## Disaster Recovery

### Backup Strategy

- **Database**: Regular backups of MariaDB/Galera
- **Ceph**: Snapshot-based backups
- **Configuration**: Version controlled in Git

### Recovery Procedures

- Documented in `docs/troubleshooting.md`
- Tested recovery procedures (to be implemented)

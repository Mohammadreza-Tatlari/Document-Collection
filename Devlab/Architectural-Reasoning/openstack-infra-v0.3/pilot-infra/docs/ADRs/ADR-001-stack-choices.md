# ADR-001: Stack choices (OpenStack, Ceph, deployment tools)

**Status:** Accepted

**Context:** Pilot needs an orchestrator, SDS, and automation with version control and minimal manual change.

**Decision:**

- **OpenStack** as cloud orchestrator (Nova, Neutron, Glance, Keystone, Cinder, Horizon, Placement).
- **Ceph** as software-defined storage (RBD for Cinder; optional RGW/CephFS later).
- **kolla-ansible** for OpenStack deployment (declarative, Git-friendly).
- **cephadm** for Ceph deployment (supported, container-based).
- **GitLab** (existing) for CI/CD and version control.
- **Prometheus + Grafana + Alertmanager** for monitoring.

**Consequences:** Standard tooling and community support; operational complexity accepted for production-grade pilot. MAAS excluded in this phase; can be added later for bare-metal provisioning.

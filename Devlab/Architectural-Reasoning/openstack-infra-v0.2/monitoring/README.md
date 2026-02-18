# Monitoring

Prometheus, Grafana, and Alertmanager configuration for the OpenStack + Ceph pilot.

- **prometheus/** – Prometheus scrape config and rules.
- **grafana/** – Dashboard and provisioning (optional).
- **alertmanager/** – Alert routing and templates.

Deploy with Ansible, Docker, or your chosen method; ensure node_exporter and Ceph mgr prometheus plugin are enabled.

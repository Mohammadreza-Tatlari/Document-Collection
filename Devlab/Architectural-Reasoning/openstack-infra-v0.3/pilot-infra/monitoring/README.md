# Monitoring – Prometheus, Grafana, Alertmanager

Configs for Prometheus (scrape node_exporter, Ceph mgr prometheus), Alertmanager, and Grafana. Deploy on Proxmox (node1) or a dedicated VM.

## Files

- `prometheus/prometheus.yml` – Scrape config (nodes, Ceph MGR)
- `alertmanager/alertmanager.yml` – Alert routing (optional)
- `grafana/` – Dashboards/provisioning (optional; export from UI or use JSON)

## Targets

- **node_exporter** (port 9100) on all 6 nodes
- **Ceph MGR prometheus** (port 9283) on the node running the active MGR
- Add OpenStack exporters later if needed (e.g. openstack-exporter)

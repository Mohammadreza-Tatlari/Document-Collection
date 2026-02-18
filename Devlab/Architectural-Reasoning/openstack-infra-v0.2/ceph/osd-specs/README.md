# Ceph OSD Specifications

This directory contains OSD (Object Storage Daemon) specifications for each node.

## Structure

Create one YAML file per node, named after the hostname:
- `compute-01-osds.yaml`
- `compute-02-osds.yaml`
- `compute-03-osds.yaml`
- `compute-04-osds.yaml`
- `compute-05-osds.yaml`

## Example OSD Specification

Each file should define which disks/devices will be used for OSDs and their device classes (SSD vs HDD).

Example `compute-01-osds.yaml`:

```yaml
service_type: osd
service_id: osd.compute-01
placement:
  host: compute-01
spec:
  data_devices:
    # SSD devices (fast storage)
    all: true  # Use all SSDs, or specify: ["/dev/sdb", "/dev/sdc"]
  db_devices:
    # Optional: WAL/DB devices for BlueStore
    # If not specified, uses same device as data
  filter_logic: AND
  data_device_filters:
    - "size >= 100GB"
  device_class: ssd  # or "hdd"
```

## Device Discovery

To discover available devices on a node:

```bash
cephadm shell -- ceph orch device ls --hostname <hostname>
```

## Applying OSD Specs

OSD specs are applied via deployment scripts in `scripts/deploy/ceph-deploy.sh`.

# Runbook: Restore OpenStack database (MariaDB/Galera)

## Scope

Restore the OpenStack control plane database from backup after corruption or loss.

## Prerequisites

- Backup of MariaDB/Galera (e.g. from `mysqldump` or Galera snapshot) stored safely.
- Access to the controller node(s) and deploy node.
- Kolla-Ansible inventory and passwords available.

## Steps

### 1. Stop OpenStack services that use the DB

On the deploy node:

```bash
kolla-ansible -i inventory/production/hosts.yml stop --yes-i-really-really-mean-it
# Or stop only API/worker services; leave base services if doing partial restore
```

### 2. Restore database on the controller(s)

- If single-node MariaDB: restore the dump to the MySQL data dir and restart MariaDB.
- If Galera: typically restore on one node (bootstrap node), then start the cluster. Follow Galera recovery procedures (e.g. start with `wsrep_recover` or from a consistent backup).

Example (single node or bootstrap node):

```bash
# On controller
mysql -u root -p < /path/to/backup.sql
# Or for Galera: restore and then start the node with appropriate wsrep options
```

### 3. Restart OpenStack services

```bash
kolla-ansible -i inventory/production/hosts.yml deploy
# Or start only the control plane first, then compute
```

### 4. Run post-deploy

```bash
kolla-ansible -i inventory/production/hosts.yml post-deploy
```

### 5. Verify

- Horizon and API respond.
- `openstack token issue` works.
- Nova, Neutron, Cinder, Glance listings return expected data.

## Prevention

- Automate DB backups (e.g. cron + `scripts/utils/backup-config.sh` or dedicated MariaDB backup job).
- Store backups off the control plane (e.g. NFS or object storage) and document retention.
- Version control and backup all Kolla/Ansible config (this repo).

# Runbook: Restore OpenStack database (MariaDB)

Use after loss of the control node or DB corruption. Assumes backups of MariaDB are taken regularly (e.g. via cron + mysqldump or kolla-ansible backup).

## Prerequisites

- Backup file of the OpenStack MariaDB (e.g. `openstack-mariadb.sql.gz`).
- New or recovered control host with the same kolla-ansible config and `passwords.yml`.
- Ceph cluster healthy (for Cinder).

## Steps

1. **Stop OpenStack services on the control node**  
   ```bash
   kolla-ansible -i inventory/multinode stop
   ```

2. **Restore MariaDB**  
   On the control host (inside the MariaDB container or host, depending on your backup method):
   ```bash
   gunzip -c openstack-mariadb.sql.gz | mysql -u root -p openstack
   ```
   Or use kolla-ansible restore if you use its backup procedure.

3. **Run database migrations**  
   ```bash
   kolla-ansible -i inventory/multinode deploy --tags precheck
   kolla-ansible -i inventory/multinode deploy --limit control
   ```

4. **Start all services**  
   ```bash
   kolla-ansible -i inventory/multinode deploy
   ```

5. **Verify**  
   Check Keystone, Horizon, Nova API, Cinder API from the management network. Run a smoke test (create project, launch VM, attach volume).

6. **Document**  
   Note the restore point and any config changes in `docs/`.

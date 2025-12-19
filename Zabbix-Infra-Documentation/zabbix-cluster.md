# A Walk through on How to deploy a HA Cluster for Zabbix Monitoring Service

In this guide, we will design and deploy a highly available Zabbix monitoring cluster built for scale. The architecture includes a two-node PostgreSQL high-availability setup managed by Patroni and backed by an etcd cluster for distributed consensus. On top of this database layer, we will run two Zabbix servers responsible for processing, storing, and evaluating monitoring data, alongside Zabbix proxies that collect metrics from monitored devices across the network.

Beyond deployment, the focus will be on performance and long-term operability. We will examine how to tune Zabbix and PostgreSQL to handle increasing workloads as the number of monitored items grows and the rate of new values per second (NVPS) rises. Finally, we will implement a hot–cold data storage strategy using TimescaleDB, allowing recent data to remain on fast storage while older data is efficiently retained on slower disks without sacrificing query performance.


To make the architecture easier to understand, the following diagram shows the full cluster we are going to deploy. This schema provides a high-level view of all major components and how they interact, so you can keep the overall design in mind as we move through the details.


![Separated Services Cluster Architecture](./media/Alpha-Model.drawio.png)
Image: Separated Cluster Architecture

It is important to note that this setup is not a strict requirement. Zabbix is flexible, and the architecture can be adjusted based on your scale, budget, and operational needs. For example, the next diagram illustrates a more compact deployment that uses fewer than seven machines to run a functional Zabbix cluster. In this scenario, a hot–cold storage strategy is not implemented because the expected data volume does not justify the added complexity.

![Minimal Cluster Architecture](./media/minimal-cluster.png)
Image: Efficient / Minimal Cluster Architecture

With these two examples, the goal is to show that there is no single “correct” architecture. Instead, you should choose a design that matches your monitoring workload and growth expectations.

In the next sections, we will build the cluster step by step. Each section focuses on a specific component, explains its role, lists its requirements, and walks through the setup process. By approaching the deployment in a modular way, you can understand each part independently and, by the end, have a fully functional Zabbix cluster ready to collect and store monitoring data.


---

## Postgresql Database Setup

In this section, we prepare the machines that will host the PostgreSQL high-availability cluster. The focus here is on operating system installation and disk layout, as these choices directly affect database performance, scalability, and long-term maintenance.

We will use two dedicated database servers with identical hardware and software configurations to ensure predictable behavior in the cluster.




### 1. Operating System Installation and Basic Preparation
Install **Ubuntu Server** on two dedicated machines. Both systems must:

- Use the same Ubuntu version
- Be fully updated
- Have two separate physical disks:

  - **SSD**: operating system and hot (recent) database data
  - **HDD**: cold (historical) database data

After installation, update the system packages on both servers:

```bash
sudo apt update && sudo apt upgrade
```

For administration, create a dedicated system user (for example, `zabbixdb-admin`) and ensure you can access both servers via SSH. Avoid hard-coding passwords in configuration files or documentation; use strong passwords or SSH keys instead.

> **Note:** You may also want to create a dedicated OS user for Zabbix-related services later, but this is not required at this stage.




### 2. Disk Partitioning and LVM Layout

Before installing PostgreSQL, we prepare the storage layout. The goal is to **isolate different types of data** so that growth in one area does not negatively affect another.

![cold-hot-storages-DBs](./media/hot-cold-storages.png)
Image: Schema of Disk Layout

The final layout will consist of three logical storage areas:

1. **OS partition** (SSD)
2. **Hot storage** for PostgreSQL tables (SSD)
3. **Cold storage** for historical data (HDD)

To keep the setup flexible and easier to extend later, we use **LVM (Logical Volume Manager)** on both disks.

#### 2.1 Preparing the HDD (Cold Storage)

Assuming the HDD is detected as `/dev/sdb` (keep in mind that the size can be varied based on your scale):

1. Create a physical volume:

   ```bash
   sudo pvcreate /dev/sdb
   pvdisplay
   ```

2. Create a volume group:

   ```bash
   sudo vgcreate hdd_space_vg1 /dev/sdb
   vgdisplay
   ```

3. Create a logical volume:

   ```bash
   sudo lvcreate -L 9.5G -n hddspace_lv1 hdd_space_vg1
   lvdisplay
   ```

4. Format the logical volume:

   ```bash
   sudo mkfs.ext4 /dev/mapper/hdd_space_vg1-hddspace_lv1
   ```

5. Create a mount point:

   ```bash
   sudo mkdir /mnt/hdd_space_mount_point
   ```

6. Mount the volume:

   ```bash
   sudo mount /dev/mapper/hdd_space_vg1-hddspace_lv1 /mnt/hdd_space_mount_point
   ```

7. Make the mount persistent by adding the following line to `/etc/fstab`:

   ```
   /dev/mapper/hdd_space_vg1-hddspace_lv1  /mnt/hdd_space_mount_point  ext4  defaults  0  0
   ```

   Verify the configuration:

   ```bash
   sudo mount -a
   df -h
   ```

#### 2.2 Preparing the SSD (Hot Storage)

Repeat the same LVM process for the SSD disk used for PostgreSQL hot data. In a production setup, use distinct and descriptive names:

- Volume Group: `ssd_space_vg1`
- Logical Volume: `ssdspace_lv1`

The operating system itself should remain on a separate SSD partition and **must not share space** with the PostgreSQL data volumes.


At this point, both database servers have a clean, isolated, and extensible storage layout. In the next section, we will install PostgreSQL and prepare it for high availability with Patroni and etcd.




### 3. Installing PostgreSQL and Preparing TimescaleDB

In this step, we install PostgreSQL on both database servers using identical versions and configurations. At this stage, we only install the software and perform basic system-level tuning. Database creation and Zabbix schema import will be handled later.



#### 3.1 Verify and Configure System Timezone

Before installing PostgreSQL, ensure that the operating system timezone is set correctly. Consistent time configuration is critical for logging, replication, and time-series data.

Set the timezone at the OS level:

```bash
sudo timedatectl set-timezone Asia/Tehran
```

If you need to adjust timezone behavior later within PostgreSQL, it can also be configured in `postgresql.conf`:

```conf
log_timezone = 'Asia/Tehran'
```

> **Note:** Setting the timezone at the OS level is preferred. Changing only PostgreSQL settings does not affect system services or other components.



#### 3.2 Important Notes on TimescaleDB and Hot/Cold Storage

This setup uses **TimescaleDB** to implement hot and cold data tiering. If you do not plan to use TimescaleDB or do not need tiered storage, you may skip:

- TimescaleDB installation
- Hot/cold disk partitioning
- TimescaleDB-specific tuning

However, if you intend to use TimescaleDB, keep the following in mind:

- TimescaleDB is installed at the **server level**
- The TimescaleDB extension must be enabled **per database**
- Since we will create a dedicated PostgreSQL database for Zabbix, the extension will be added *after* that database is created



#### 3.3 Install PostgreSQL and TimescaleDB Packages ([TigerData Installation](https://www.tigerdata.com/docs/self-hosted/latest/install/installation-linux))

Perform the following steps **on both database servers**.

1. Install required dependencies:

   ```bash
   sudo apt install -y gnupg postgresql-common apt-transport-https lsb-release wget
   ```

2. Enable the official PostgreSQL APT repository:

   ```bash
   sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
   ```

3. Add the TimescaleDB repository:

   ```bash
   echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main" \
   | sudo tee /etc/apt/sources.list.d/timescaledb.list
   ```

4. Import the TimescaleDB GPG key:

   ```bash
   wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey \
   | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg
   ```

5. Update package lists:

   ```bash
   sudo apt update
   ```

6. Install PostgreSQL 17 with TimescaleDB support:

   ```bash
   sudo apt install -y timescaledb-2-postgresql-17 postgresql-client-17
   ```


#### 3.4 Initial PostgreSQL Tuning with `timescaledb-tune`

TimescaleDB provides a helper tool that adjusts PostgreSQL parameters based on system resources.

Run the tuning tool:

```bash
sudo timescaledb-tune
```

This tool modifies settings in:

```
/etc/postgresql/17/main/postgresql.conf
```

Review the suggested changes carefully before applying them, especially in production environments. A restart of PostgreSQL will be required after tuning.


At this point, PostgreSQL is installed and configured to support TimescaleDB on both database servers. However, the TimescaleDB extension has **not yet** been enabled in any database. This is expected, as the Zabbix database will be created and initialized in a later step.


#### Side Notes of Post Postgresql Installation :

#### Connecting Postgresql to PgAdmin
If Postgresql DBs need to connected to PgAdmin, Follow This Quick [StackOverFlow Guideline](https://stackoverflow.com/questions/50049463/remote-postgresql-connection-with-pgadmin)

#### Enable PostgreSQL Log Collection and Set Log Level
> Note: In our setup, this step is usually managed by Patroni. Only apply these changes manually if Patroni is not controlling the configuration or if you have confirmed it is safe to do so.

PostgreSQL can collect its own logs and control how much detail is written. Enabling this is useful when you want to see warnings or messages generated by commands such as `RAISE NOTICE`.

#### Step 1: Edit the PostgreSQL configuration file

Open the PostgreSQL configuration file:

```bash
sudo vim /etc/postgresql/17/main/postgresql.conf
```

#### Step 2: Enable the log collector

Make sure the following setting is enabled:

```conf
logging_collector = on
```

This tells PostgreSQL to capture logs and write them to log files instead of only printing them to the console.

#### Step 3: Set the log level

Set the minimum log level to `info` (or `debug` if you need more detailed output):

```conf
log_min_messages = info
```

- `info` is usually sufficient for beginners and day-to-day troubleshooting.
- `debug` produces very verbose logs and should be used only when necessary.

With this setting, PostgreSQL will log messages such as `RAISE NOTICE`, warnings, and errors.

#### Step 4: Verify the log location

By default, PostgreSQL will store logs in:

```text
/var/lib/postgresql/17/main/log/
```

You can check this directory to confirm that new log files are being created.

#### Optional: Check log destination

You may also want to confirm that logs are being sent to a supported destination, such as `stderr` or `csvlog`:

```conf
log_destination = 'stderr'
```

This works together with `logging_collector = on` to ensure logs are properly written to disk.




### 4. Creating PostgreSQL Tablespaces for Hot and Cold Storage

Now that both SSD and HDD disks are mounted and isolated at the operating system level, we can create PostgreSQL tablespaces to implement hot and cold storage.

A **tablespace** tells PostgreSQL *where* to store physical data files on disk. By separating tablespaces, we can control which data lives on fast SSD storage and which data is placed on slower HDD storage.

> **Important:** PostgreSQL accesses the filesystem exclusively using the Linux user `postgres`. Database roles (such as `zabbix`) do not interact with the OS directly and must never own filesystem paths.



#### 4.1 Prepare Tablespace Directories and Permissions

Create dedicated directories inside each mount point and assign ownership to the `postgres` user.

##### HDD (Cold Storage)

```bash
sudo mkdir -p /mnt/hdd_space_mount_point/pg_cold_storage
sudo chown postgres:postgres /mnt/hdd_space_mount_point/pg_cold_storage
sudo chmod 700 /mnt/hdd_space_mount_point/pg_cold_storage
```

##### SSD (Hot Storage)

```bash
sudo mkdir -p /mnt/ssd_space_mount_point/pg_hot_storage
sudo chown postgres:postgres /mnt/ssd_space_mount_point/pg_hot_storage
sudo chmod 700 /mnt/ssd_space_mount_point/pg_hot_storage
```

These permissions ensure that only PostgreSQL can read or write database files, which is the recommended and safest configuration.



#### 4.2 Create Tablespaces in PostgreSQL

Log in to PostgreSQL as the `postgres` superuser:

```bash
sudo -u postgres psql
```

Create the tablespaces:

```sql
CREATE TABLESPACE ssd_hot_storage
  LOCATION '/mnt/ssd_space_mount_point/pg_hot_storage';

CREATE TABLESPACE hdd_cold_storage
  LOCATION '/mnt/hdd_space_mount_point/pg_cold_storage';
```

Verify that the tablespaces were created successfully:

```sql
\db+
```



#### 4.3 Grant Tablespace Permissions to the Zabbix Database Role

Although the filesystem is owned by `postgres`, access control for tablespaces is handled inside PostgreSQL.

Create the Zabbix User:

```sh
sudo -u postgres createuser --pwprompt zabbix
```

Grant the required privileges to the `zabbix` database role (Note):

```sql
GRANT ALL PRIVILEGES ON TABLESPACE ssd_hot_storage TO zabbix;
GRANT ALL PRIVILEGES ON TABLESPACE hdd_cold_storage TO zabbix;
```

This allows the Zabbix database to create tables and indexes in the appropriate storage tier without exposing filesystem access.



---

## Patroni and ETCD Configuration

Before deploying Patroni, we must set up an etcd cluster. Etcd acts as a distributed key–value store and is used by Patroni to coordinate leader election, failover, and cluster state for PostgreSQL.

In this guide, we deploy a three-node etcd quorum, which is the recommended minimum for high availability.



### Etcd Quorum Servers


We use three dedicated servers with identical resources:
- CPU: 4 cores
- RAM: 4 GB
- Disk: 15 GB

![ETCD Quarum Cluster](./media/etcd-cluster.png)
Image: ETCD Cluster as A DCS 

> **Important:** All nodes must have consistent system time configuration.

```bash
sudo timedatectl set-timezone Asia/Tehran
```

### Installing Etcd on All Nodes
The following steps must be repeated on **all three etcd servers**.


#### 1. Download the Etcd Binary

Download a specific, pinned version to avoid unexpected behavior:

```bash
wget https://github.com/etcd-io/etcd/releases/download/v3.6.1/etcd-v3.6.1-linux-amd64.tar.gz
```

Extract the archive:
```bash
tar -xzf etcd-v3.6.1-linux-amd64.tar.gz
```

#### 2. Install Etcd Binaries

Move the binaries to a standard system path:
```bash
sudo mv etcd-v3.6.1-linux-amd64/etcd* /usr/local/bin/
```

Verify installation:
```bash
etcd --version
etcdctl version
```

#### 3. Create a Dedicated Etcd System User

Etcd should run as a non-login system user:

```bash
sudo useradd --system --home /var/lib/etcd --shell /usr/sbin/nologin etcd
```

#### 4. Create Configuration and Data Directories
```bash
sudo mkdir -p /etc/etcd
sudo mkdir -p /var/lib/etcd
sudo chown -R etcd:etcd /etc/etcd /var/lib/etcd
```

Create the environment configuration file:
```bash
sudo -u etcd touch /etc/etcd/etcd.env
```

#### 5. Create the systemd Service

Create the service definition:
```bash
sudo nano /etc/systemd/system/etcd.service
```

```ini
[Unit]
Description=etcd distributed key-value store
Documentation=https://github.com/etcd-io/etcd
After=network-online.target
Wants=network-online.target

[Service]
User=etcd
Group=etcd
WorkingDirectory=/var/lib/etcd
EnvironmentFile=/etc/etcd/etcd.env
ExecStart=/usr/local/bin/etcd
Restart=always
RestartSec=10
LimitNOFILE=40000

[Install]
WantedBy=multi-user.target


Reload systemd and enable the service:
```sh
sudo systemctl daemon-reload
sudo systemctl enable etcd
```

#### 6. Configure Etcd Environment Variables

Edit `/etc/etcd/etcd.env` on **each node**, adjusting `ETCD_NAME` and IP addresses accordingly.

Example for **etcd-mgt-srv1 (172.24.24.11)**:
```sh
ETCD_NAME="etcd-mgt-srv1"
ETCD_DATA_DIR="/var/lib/etcd"

ETCD_INITIAL_CLUSTER="etcd-mgt-srv1=http://172.24.24.11:2380,etcd-mgt-srv2=http://172.24.24.12:2380,etcd-mgt-srv3=http://172.24.24.13:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"

ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.24.24.11:2380"

ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://172.24.24.11:2379"
```

> **Note:** This guide uses **plain HTTP** for simplicity. In production environments, TLS should always be enabled.

Ensure ownership is correct:

```bash
sudo chown -R etcd:etcd /etc/etcd
```

#### 7. Start Etcd and Verify Cluster Health

Start the service:
```bash
sudo systemctl start etcd
```

Check logs:
```bash
journalctl -u etcd -xe
```

Verify cluster health:
```bash
etcdctl endpoint health
etcdctl member list
```

To view cluster status and leader information:
```bash
etcdctl \
  --endpoints=http://172.24.24.11:2379,http://172.24.24.12:2379,http://172.24.24.13:2379 \
  endpoint status --write-out=table
```

At this point, the etcd quorum is operational and ready to be used by Patroni. In the next section, we will deploy Patroni and integrate it with this etcd cluster to manage PostgreSQL high availability and failover.




### Patroni Configuration and ETCD Integration
After verifying that the etcd cluster is healthy and leader election is working correctly, we can deploy **Patroni** on the PostgreSQL servers. Patroni will manage PostgreSQL high availability by coordinating leader election, replication, and failover using etcd as its distributed configuration store.

This section must be performed on **both PostgreSQL servers** unless explicitly stated otherwise.

![patroni-etcd](./media/patroni-etcd.png)
Image: Patroni Services in Schema


#### 1. Install Patroni
Install Patroni from the Ubuntu repositories:
```bash
sudo apt install -y patroni
```

This installs Patroni as a systemd-managed service.



#### 2. Create the Patroni Configuration Directory and File
Create the configuration directory and file:
```bash
sudo mkdir -p /etc/patroni
sudo touch /etc/patroni/config.yml
```

Ensure the file is readable by PostgreSQL later (ownership will be adjusted after validation).



#### 3. Ensure Patroni Is Not Running
Patroni should not be running before the configuration is complete. If it started automatically, stop it:
```bash
sudo systemctl stop patroni
```

> Using `patronictl pause` is not appropriate before the cluster exists.



#### 4. Configure Patroni (`config.yml`)
Each PostgreSQL server must have a **unique node name and IP address**.
The following example is for **zabbix_db_srv1 (172.24.24.17)**.

```yaml
scope: zabbixdb_cluster
namespace: /service/
name: zabbix_db_srv1   # Must be unique per node

etcd3:
  hosts: 172.24.24.11:2379,172.24.24.12:2379,172.24.24.13:2379
  protocol: http

restapi:
  listen: 0.0.0.0:8008
  connect_address: 172.24.24.17:8008

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 5
    retry_timeout: 4
    maximum_lag_on_failover: 1048576
    synchronous_mode: on

  initdb:
    - encoding: UTF8
    - data-checksums

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 172.24.24.17:5432
  data_dir: /var/lib/postgresql/17/main
  config_dir: /etc/postgresql/17/main
  bin_dir: /usr/lib/postgresql/17/bin

  pg_hba:
    - host all all 127.0.0.1/32 scram-sha-256
    - host all all ::1/128 scram-sha-256
    - host all all 0.0.0.0/0 scram-sha-256

    - host replication replicator_user 172.24.24.17/32 scram-sha-256
    - host replication replicator_user 172.24.24.18/32 scram-sha-256

    - local all postgres peer

  authentication:
    superuser:
      username: postgres
      password: "<strong-password>"
    replication:
      username: replicator_user
      password: "<strong-password>"

  parameters:
    wal_level: replica
    max_wal_senders: 3
    max_replication_slots: 4
    max_connections: 100

    shared_preload_libraries: timescaledb

    shared_buffers: 4GB
    effective_cache_size: 10GB
    maintenance_work_mem: 2GB
    work_mem: 64MB 
    huge_pages: off
    checkpoint_completion_target: 0.9
    min_wal_size: 128MB
    max_wal_size: 4GB

    synchronous_commit: remote_write

    max_worker_processes: 10 #(a little less than cpu)
    max_parallel_workers: 8 #(less than cpu)
    max_parallel_workers_per_gather: 6 #(can increase based on CPU Core)

    autovacuum: on
    autovacuum_max_workers: 4

    wal_log_hints: on
    use_pg_rewind: true
    remove_data_directory_on_diverged_timelines: true

    log_directory: '/var/log/postgresql/patroni/'
    logging_collector: on
    log_min_messages: notice # or INFO
```


#### 5. Validate the Configuration
Before starting Patroni, validate the YAML file:
```bash
patroni --validate-config /etc/patroni/config.yml
```


#### 6. Set Correct File Ownership

Patroni runs PostgreSQL as the `postgres` user, so ensure proper ownership:

```bash
sudo chown -R postgres:postgres /etc/patroni
```


#### 7. Start Patroni on Both Servers
Start Patroni:
```bash
sudo systemctl start patroni
```

Follow the logs:
```bash
journalctl -u patroni -f
```

Expected output on the standby node:
```
INFO: no action. I am (zabbix_db_srv2), a secondary, and following a leader (zabbix_db_srv1)
```


#### 8. Reloading and Updating Configuration
To reload PostgreSQL parameters without restarting Patroni:
```bash
patronictl -c /etc/patroni/config.yml reload zabbixdb_cluster
```

To modify values stored in etcd (`bootstrap.dcs`):
```bash
patronictl -c /etc/patroni/config.yml edit-config
```

> Changes in the DCS are propagated dynamically and do not require service restarts.


#### 9. Finalize ETCD Cluster State
Once Patroni is fully operational, update **all etcd nodes**:

Edit `/etc/etcd/etcd.env` and change:
```sh
ETCD_INITIAL_CLUSTER_STATE="existing"
```

Restart etcd on each node after the change.


At this point, Patroni is managing PostgreSQL leader election and replication using etcd. The cluster is now resilient to node failures and ready for database initialization and Zabbix schema deployment.



---

## Preparing HAProxy and Keepalived for PostgreSQL High Availability

To provide a stable and highly available entry point to the PostgreSQL cluster, we place **HAProxy** and **Keepalived** in front of the database nodes.

- **HAProxy** routes client connections to the current PostgreSQL primary node.
- **Keepalived** provides a floating Virtual IP (VIP) and handles failover between HAProxy nodes.

Zabbix and other clients will connect **only to the VIP**, never directly to database nodes.


### Architecture Overview

We deploy two HAProxy servers in an active–standby configuration:

- **haproxy-v-srv1** — `172.24.24.19`
- **haproxy-v-srv2** — `172.24.24.20`
- **Virtual IP (VIP)** — `172.24.24.26`

If the active HAProxy node fails, Keepalived automatically moves the VIP to the standby node.

![HAProxy-Schema](./media/HAProxy.png)
Image: HAProxy On Schema

### Installing and Configuring HAProxy

Perform the following steps on **both HAProxy servers**.


### 1. Install HAProxy
```bash
sudo apt install -y haproxy
```


#### 2. Configure HAProxy
Edit the HAProxy configuration file:
```bash
sudo nano /etc/haproxy/haproxy.cfg
```

Below is a working configuration for routing PostgreSQL traffic using **Patroni’s REST API** to detect the current primary node.

> **Note:** Values such as IP addresses and connection limits must be adjusted to your environment.

```cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    maxconn 100   # Should align with PostgreSQL max_connections

defaults
    log global
    mode tcp
    retries 3
    timeout connect 5s
    timeout client 30m
    timeout server 30m
    timeout check 3s

frontend postgres_frontend
    bind *:5432
    default_backend postgres_backend

backend postgres_backend
    option tcplog
    option tcp-check
    option httpchk GET /primary
    http-check expect status 200

    server zabbix-db-srv1 172.24.24.17:5432 check port 8008 inter 3s fall 5 rise 3
    server zabbix-db-srv2 172.24.24.18:5432 check port 8008 inter 3s fall 5 rise 3
```

#### Why This Works
- PostgreSQL traffic uses **TCP**
- Health checks query **Patroni’s REST API** on port `8008`
- Only the current primary responds with HTTP `200` to `/primary`
- HAProxy automatically routes connections to the primary


#### 3. Apply and Verify HAProxy Configuration
Reload HAProxy:
```bash
sudo systemctl reload haproxy
```

If reload fails, restart instead:
```bash
sudo systemctl restart haproxy
```

Check logs:
```bash
sudo journalctl -u haproxy -f
```

Monitor active connections:
```bash
sudo watch -n 1 "ss -tan | grep :5432"
```


### Installing and Configuring Keepalived
Keepalived manages the **Virtual IP** and ensures that only one HAProxy node is active at a time.


#### 1. Install Keepalived
```bash
sudo apt install -y keepalived
```


#### 2. Create the Keepalived Configuration
Edit the configuration file:
```bash
sudo nano /etc/keepalived/keepalived.conf
```

Example configuration for the **MASTER** node:
```cfg
global_defs {
    enable_script_security
    script_user keepalived_script
}

vrrp_script check_haproxy {
    script "/etc/keepalived/check_haproxy.sh"
    interval 2
    fall 3
    rise 2
}

vrrp_instance VI_1 {
    state MASTER            # BACKUP on the second node
    interface ens160        # Adjust to your network interface
    virtual_router_id 51
    priority 100            # Use lower value (e.g., 90) on BACKUP
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass "example-password"
    }

    virtual_ipaddress {
        172.24.24.26
    }

    track_script {
        check_haproxy
    }
}
```

> **Security note:**
> Use strong, private values for `auth_pass`. Do not reuse example passwords in production.


#### 3. Create the HAProxy Health Check Script
```bash
sudo nano /etc/keepalived/check_haproxy.sh
```

```bash
#!/bin/bash

PORT=5432

if ! pidof haproxy > /dev/null; then
    exit 1
fi

if ! ss -ltn | grep -q ":${PORT}"; then
    exit 2
fi

exit 0
```

Make it executable:
```bash
sudo chmod +x /etc/keepalived/check_haproxy.sh
```


#### 4. Create a Dedicated Script User
```bash
sudo useradd -r -s /usr/sbin/nologin keepalived_script
sudo chown keepalived_script:keepalived_script /etc/keepalived/check_haproxy.sh
sudo chmod 700 /etc/keepalived/check_haproxy.sh
```


#### 5. Start and Verify Keepalived
```bash
sudo systemctl restart keepalived
```

Monitor logs:
```bash
sudo journalctl -u keepalived -f
```

Verify VIP availability:
```bash
ping 172.24.24.26
```

You should see the VIP move automatically if:
- HAProxy stops
- The active node goes offline


At this stage:

- Zabbix connects to `172.24.24.26:5432`
- HAProxy forwards traffic to the PostgreSQL primary
- Patroni controls database leadership
- Keepalived guarantees a stable access IP

This completes the **database access layer** of the Zabbix cluster.



---

## Creating the Zabbix Database and Enabling TimescaleDB 
In this step we will:

1. Create an **empty Zabbix database** on the **hot (SSD) tablespace**
2. Ensure the **zabbix role** can connect properly
3. Enable the **TimescaleDB extension**
4. Import the **Zabbix PostgreSQL schema**
5. Convert Zabbix tables to TimescaleDB hypertables

> **Important principle**
>
> - Tablespace is chosen **at database creation time**
> - TimescaleDB is enabled **before Zabbix starts**
> - Zabbix schema must be imported **before TimescaleDB schema**


### 1. Create the Zabbix Role and Database 
If you already created the `zabbix` role during the Zabbix installation wizard, **verify it instead of recreating it**.


#### 1.1 Connect as PostgreSQL superuser
```bash
sudo -u postgres psql
```

#### 1.2 Create or Verify the Zabbix Role

If the role does not exist:
```sql
CREATE ROLE zabbix WITH LOGIN PASSWORD 'zabbix';
```

If it already exists and you only need to set the password:
```sql
ALTER ROLE zabbix WITH PASSWORD 'zabbix';
```

Verify:
```sql
\du+
```

> **Do NOT grant SUPERUSER in production**
> Zabbix does **not** require superuser privileges.
> Granting it hides permission problems and weakens security.


#### 1.3 Create the Zabbix Database on SSD Tablespace
Exit `psql` if needed, then:

```bash
sudo -u postgres createdb \
  -O zabbix \
  --tablespace=ssd_hot_storage \
  zabbix
```

Verify the tablespace assignment:
```sql
SELECT d.datname, ts.spcname AS default_tablespace
FROM pg_database d
JOIN pg_tablespace ts ON d.dattablespace = ts.oid
WHERE d.datname = 'zabbix';
```

You should see:
```
zabbix | ssd_hot_storage
```


### 2. Enable TimescaleDB Extension 
TimescaleDB must be **installed at OS level first** (already covered in previous sections).


#### 2.1 Connect to the Zabbix Database
You can connect locally:

```bash
sudo -u zabbix psql zabbix
```

Or through HAProxy (recommended for consistency):

```bash
psql "postgres://zabbix:zabbix@172.24.24.26:5432/zabbix"
```


#### 2.2 Create the TimescaleDB Extension - [Zabbix TimescaleDB](https://www.zabbix.com/documentation/current/en/manual/appendix/install/timescaledb)

Inside `psql`:
```sql
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
```

Verify:
```sql
\dx
```

You should see `timescaledb` listed.


### 3. Import the Zabbix PostgreSQL Schema

Zabbix ships its database schema as compressed SQL files.

#### 3.1 Install Zabbix SQL Scripts

Make sure the Zabbix server packages are installed so the SQL files exist:
```bash
ls /usr/share/zabbix/sql-scripts/postgresql/
```

You should see files like:
- `server.sql.gz`
- `timescaledb/schema.sql`


#### 3.2 Import the Core Zabbix Schema (Required First)

```bash
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz \
  | sudo -u zabbix psql zabbix
```

This creates:
- Tables
- Indexes
- Functions
- Initial metadata


### 4. Convert Zabbix Tables to TimescaleDB

After the **core schema** is in place, apply the TimescaleDB schema.
```bash
cat /usr/share/zabbix/sql-scripts/postgresql/timescaledb/schema.sql \
  | sudo -u zabbix psql zabbix
```

This step:
- Converts history and trend tables into hypertables
- Enables chunking and compression logic

> ⚠️ **Do not reverse this order**
> Importing the TimescaleDB schema before `server.sql` will fail.


### 5. Final Checks

#### 5.1 Confirm Hypertables

```sql
SELECT hypertable_name
FROM timescaledb_information.hypertables;
```

You should see tables such as:

- `history`
- `history_uint`
- `trends`
- `trends_uint`



#### 5.2 Zabbix Compatibility Warning (in Further Steps)

If Zabbix logs show an error like:
```
Unsupported DB version
```

Edit:
```bash
sudo nano /etc/zabbix/zabbix_server.conf
```

Set:
```ini
AllowUnsupportedDBVersions=1
```

Restart Zabbix:
```bash
sudo systemctl restart zabbix-server
```


At this point:

- Zabbix database exists on **SSD (hot storage)**
- TimescaleDB is enabled and active
- Zabbix tables are hypertables
- Zabbix can safely start and ingest metrics

This completes the **database initialization phase**.



---

## Create Cluster Move Chunk Policy and Job Scheduler for old Data (SSD to HDD Tiering)

After completing the partitioning and tablespace configuration for **ssd_tablespace** and **hdd_tablespace**, you must create a clustered index for each Zabbix table and apply a data-movement policy to it. A scheduled job must then be configured for each policy. Finally, each configuration should be verified.

All required steps are described in the following sections.


### Step 0: Verify whether all tables are hypertables:

```sql
SELECT
    hypertable_schema,
    hypertable_name
FROM
    timescaledb_information.hypertables
WHERE
    hypertable_name IN ('auditlog', 'history_uint', 'history', 'history_str', 'history_text', 'history_log', 'history_bin', 'trends_uint', 'trends');
```


### STEP 1: Identify the Primary key Index for each table
> history_text, 
> history_log, 
> history_bin, 
> trends_uint, 
> trends, 
> auditlog (audid), 
> history (clock), 
> history_str

``` sql
SELECT
    t.relname AS table_name,
    i.relname AS index_name,
    pg_get_indexdef(idx.indexrelid) AS index_definition
FROM
    pg_class t,
    pg_class i,
    pg_index idx,
    pg_attribute a
WHERE
    t.oid = idx.indrelid
    AND i.oid = idx.indexrelid
    AND idx.indnatts > 0 -- Has at least one attribute
    AND idx.indisprimary -- Is a primary key
    AND t.relname = 'history_uint'; -- Repeate This Process for all: history_text, history_log, history_bin, trends_uint, trends, auditlog (audid), history (clock), history_str
```

or 
```sql
SELECT
    t.relname AS table_name,
    i.relname AS index_name,
    pg_get_indexdef(idx.indexrelid) AS index_definition
FROM
    pg_class t
JOIN pg_index idx ON t.oid = idx.indrelid
JOIN pg_class i ON idx.indexrelid = i.oid
WHERE
    idx.indisprimary = true -- This filters for primary key indexes
    AND t.relname IN ('history_uint', 'history_text', 'history_log', 'history_bin', 'trends_uint', 'trends', 'auditlog', 'history', 'history_str');
```


### STEP 2: Perform Cluster Operation

``` sql
-- IMPORTANT: This step will acquire an ACCESS EXCLUSIVE lock on the history_uint table, 
-- which will block all reads and writes to that table until it completes. 
-- Plan for downtime or a maintenance window.
-- Ensure you are connected to the 'zabbix' database
-- Replace 'history_uint_pkey' if your primary key index has a different name
-- Remember to Replace both "TABLE NAME" and "TABLE PRIMARY KEY"
CLUSTER VERBOSE history_uint USING history_uint_pkey;
CLUSTER VERBOSE history_text USING history_text_pkey;
CLUSTER VERBOSE history_log USING history_log_pkey;
CLUSTER VERBOSE history_bin USING history_bin_pkey;
CLUSTER VERBOSE trends_uint USING trends_uint_pkey;
CLUSTER VERBOSE trends USING trends_pkey;
CLUSTER VERBOSE auditlog USING auditlog_pkey;
CLUSTER VERBOSE history USING history_pkey;
CLUSTER VERBOSE history_str USING history_str_pkey;
```


### STEP 3: Permanently cluster the hypertable on the selected index.
(This step addresses the TimescaleDB issue related to unknown clusters and resolves it.)
This is a one-time operation and only needs to be executed once.
```sql
-- This tells PostgreSQL to use history_uint_pkey as the default for future CLUSTER commands on this table
ALTER TABLE history_uint CLUSTER ON history_uint_pkey;
-- For history_text
ALTER TABLE history_text CLUSTER ON history_text_pkey;
-- For history_log
ALTER TABLE history_log CLUSTER ON history_log_pkey;
-- For history_bin
ALTER TABLE history_bin CLUSTER ON history_bin_pkey;
-- For trends_uint
ALTER TABLE trends_uint CLUSTER ON trends_uint_pkey;
-- For trends
ALTER TABLE trends CLUSTER ON trends_pkey;
-- For auditlog
ALTER TABLE auditlog CLUSTER ON auditlog_pkey; ---
-- For history
ALTER TABLE history CLUSTER ON history_pkey;
-- For history_str
ALTER TABLE history_str CLUSTER ON history_str_pkey;

```


### STEP 4: Modify the moving-chunks function to use clustering.(Moving Chunk Functionality)
its getting the **hypertable_name** and **age_threshold** that will send data based on them:

``` sql

--- updated code: UPDATED MOVER

CREATE OR REPLACE FUNCTION move_old_chunks_to_cold_storage(job_id INT, config JSONB)
    RETURNS void
    LANGUAGE plpgsql AS $$
DECLARE
    v_hypertable TEXT;
    v_age_threshold INTERVAL;
    v_chunk_name TEXT;
    v_chunk_tablespace TEXT;
    v_target_timestamp TIMESTAMPTZ;
    v_qualified_chunk_name TEXT;
BEGIN
    v_hypertable := config->>'hypertable_name';
    v_age_threshold := (config->>'age_threshold')::INTERVAL;

    IF v_hypertable IS NULL OR v_age_threshold IS NULL THEN
        RAISE EXCEPTION 'Configuration must include hypertable_name and age_threshold';
    END IF;

    -- Calculate target timestamp
    v_target_timestamp := NOW() - v_age_threshold;

    RAISE NOTICE 'Running chunk moving job for hypertable: %. Moving chunks older than %',
                 v_hypertable, v_target_timestamp;

    -- Debug information
    RAISE NOTICE 'Current chunks for hypertable:';
    FOR v_chunk_name IN
        SELECT c.chunk_name || ' (creation_time: ' || c.chunk_creation_time || ')'
        FROM timescaledb_information.chunks AS c
        WHERE c.hypertable_name = v_hypertable
        ORDER BY c.chunk_creation_time DESC
        LIMIT 5
    LOOP
        RAISE NOTICE '%', v_chunk_name;
    END LOOP;

    FOR v_chunk_name, v_chunk_tablespace IN
        SELECT
            c.chunk_name,
            c.chunk_tablespace
        FROM timescaledb_information.chunks AS c
        WHERE c.hypertable_name = v_hypertable
          AND c.chunk_creation_time < v_target_timestamp
          AND (c.chunk_tablespace IS NULL OR c.chunk_tablespace != 'hdd_cold_storage')
    LOOP
        v_qualified_chunk_name := '_timescaledb_internal.' || v_chunk_name;

        RAISE NOTICE 'Moving chunk: % (created at: %) from tablespace: % to hdd_cold_storage',
                     v_chunk_name,
                     (SELECT chunk_creation_time 
                      FROM timescaledb_information.chunks 
                      WHERE chunk_name = v_chunk_name),
                     COALESCE(v_chunk_tablespace, 'default (ssd_hot_storage)');

        PERFORM move_chunk(v_qualified_chunk_name, 'hdd_cold_storage', 'hdd_cold_storage');

    END LOOP;

    RAISE NOTICE 'Chunk moving job finished for hypertable: %.', v_hypertable;
END;
$$;

```

#### 4. 1. to verify which chunks will be moved.
```sql

SELECT 
    chunk_name,
    chunk_creation_time,
    chunk_tablespace,
    NOW() - chunk_creation_time as chunk_age
FROM timescaledb_information.chunks
WHERE hypertable_name = 'trends_uint' --this name is dynamic
ORDER BY chunk_creation_time DESC;

```


### STEP 5 call the function to test whether chunk will be moved.

```sql
SELECT move_old_chunks_to_cold_storage(
    NULL,
    JSONB_BUILD_OBJECT(
        'hypertable_name', 'history_uint',
        'age_threshold', '10 days' -- Adjust as needed to capture chunks
    )
);

-- Calling the Function
SELECT move_old_chunks_to_cold_storage(
    NULL,
    JSONB_BUILD_OBJECT(
        'hypertable_name', 'trends_uint',
        'age_threshold', '19 hours'
    )
);

```

### Step 6 Testing
1. **Back Test Step**

    0. call the function to assure that its working.
    ``` sql
    SELECT move_old_chunks_to_cold_storage(
        NULL,
        JSONB_BUILD_OBJECT(
            'hypertable_name', 'history_uint', -- replace the hypertable_name with other hypertables.
            'age_threshold', '10 days' -- Adjust as needed to capture chunks (for the first time it interval can be vary)
        )
    );

    SELECT * FROM timescaledb_information.jobs;
    SELECT * FROM timescaledb_information.job_stats;
    SELECT * FROM timescaledb_information.chunks;
    -- Check history_uint's chunk time interval:
    SELECT * FROM timescaledb_information.hypertables WHERE hypertable_name = 'history_uint';
    ```

    1. verify if any error is present in log files. (the log collector and log level should be indicated in step 3 (install Postgresql and configure it)) </br>
    - `less /var/lib/postgresql/17/main/log/postgresql-2025-06-2xxx.log`
    
    2. check if each table has `default_tablespace` as `ssd_hot_storage` (this step should be configured in Main STEP 5)
        ``` sql
        SELECT d.datname, ts.spcname AS default_tablespace
        FROM pg_database d
        JOIN pg_tablespace ts ON d.dattablespace = ts.oid
        WHERE d.datname = 'zabbix';
        ```


### STEP 7: CREATE Scheduled psql job for each Zabbix Hypertable (The Backtest Should be approved) </br>
note that each table needs to be 

**CAUTION**: </br>
For Test we can set the age_threshold to 1 day to see if they move accurately. 

``` sql
--- UPDATED JOBS 
SELECT add_job('move_old_chunks_to_cold_storage', 
    schedule_interval => '1 day', 
    config => JSONB_BUILD_OBJECT('hypertable_name', 'history', 'age_threshold', '30 days'), 
    initial_start => CURRENT_DATE + INTERVAL '1 day' + INTERVAL '1 hour',
    scheduled => true, 
    fixed_schedule => true);

-- For history_str: Move chunks older than, say, 30 days
SELECT add_job('move_old_chunks_to_cold_storage', 
    schedule_interval => '1 day', 
    config => JSONB_BUILD_OBJECT('hypertable_name', 'history_uint', 'age_threshold', '30 days'),
    initial_start=> CURRENT_DATE + INTERVAL '1 day' + INTERVAL '2 hours',
    scheduled => true,
    fixed_schedule => true);

-- For history_log: Also potentially 90 days or more 
SELECT add_job('move_old_chunks_to_cold_storage', 
    schedule_interval => '1 day', 
    config => JSONB_BUILD_OBJECT('hypertable_name', 'history_log', 'age_threshold', '30 days'),
    initial_start=> CURRENT_DATE + INTERVAL '1 day' + INTERVAL '3 hours',
    scheduled => true,
    fixed_schedule => true);

-- For history_text: Move chunks older than 90 days (text data can be less frequently accessed)
SELECT add_job('move_old_chunks_to_cold_storage', 
    schedule_interval => '1 day', 
    config => JSONB_BUILD_OBJECT('hypertable_name', 'history_text', 'age_threshold', '60 days'), --90 days
    initial_start=> CURRENT_DATE + INTERVAL '1 day' + INTERVAL '4 hours',
    scheduled => true,
    fixed_schedule => true);
    
SELECT add_job('move_old_chunks_to_cold_storage', 
    schedule_interval => '1 day', 
    config => JSONB_BUILD_OBJECT('hypertable_name', 'history_str', 'age_threshold', '30 days'),
    initial_start=> CURRENT_DATE + INTERVAL '1 day' + INTERVAL '5 hours',
    scheduled => true,
    fixed_schedule => true);

-- For history_bin: (often smaller)
SELECT add_job('move_old_chunks_to_cold_storage', 
    schedule_interval => '1 day', 
    config => JSONB_BUILD_OBJECT('hypertable_name', 'history_bin', 'age_threshold', '30 days'),
    initial_start=> CURRENT_DATE + INTERVAL '1 day' + INTERVAL '6 hours',
    scheduled => true,
    fixed_schedule => true);

-- Trends tables (smaller volume) - later in the morning
SELECT add_job('move_old_chunks_to_cold_storage', 
    schedule_interval => '1 day', 
    config => JSONB_BUILD_OBJECT('hypertable_name', 'trends', 'age_threshold', '180 days'), --365 days
    initial_start=> CURRENT_DATE + INTERVAL '1 day' + INTERVAL '7 hours',
    scheduled => true,
    fixed_schedule => true);

-- For trends and trends_uint: These are already aggregated, often kept "hotter" or tiered differently.
-- You might choose a longer age_threshold or even keep them entirely on SSD if their size is manageable.
SELECT add_job('move_old_chunks_to_cold_storage', 
    schedule_interval => '1 day', 
    config => JSONB_BUILD_OBJECT('hypertable_name', 'trends_uint', 'age_threshold', '180 days'), --365 days
    initial_start=> CURRENT_DATE + INTERVAL '1 day' + INTERVAL '8 hours',
    scheduled => true,
    fixed_schedule => true);

-- Auditlog (lowest volume) - last to run
SELECT add_job('move_old_chunks_to_cold_storage', 
    schedule_interval => '1 day', 
    config => JSONB_BUILD_OBJECT('hypertable_name', 'auditlog', 'age_threshold', '60 days'), --90 days
    initial_start=> CURRENT_DATE + INTERVAL '1 day' + INTERVAL '9 hours',
    scheduled => true,
    fixed_schedule => true);
```


### Keep Monitoring for Further Ensurrance:
- Monitor `timescaledb_information.jobs` and `timescaledb_information.job_stats` to ensure each job runs successfully.
- Periodically check `timescaledb_information.chunks` for each hypertable to observe the `chunk_tablespace` column changing from `NULL`/`ssd_hot_storage` to `hdd_cold_storage` for aged chunks.

- **to check the function or make changes:** </br>
Server > Databases > zabbix > Schemas > Public > Functions > (look for that function) > Right Click and SELECT `CREATE`
- `SELECT * FROM timescaledb_information.job_stats;` => check last run for each job 
- `SELECT * FROM  timescaledb_information.jobs;` => check out if new job is added to timescaledb jobs
- `SELECT * FROM timescaledb_information.jobs WHERE proc_name = 'move_old_chunks_to_cold_storage';` => to see list of jobs in queue that are related to move_old_chunks

- check the disk size exchange on SSD and HDD storage: </br>
``` sql
SELECT spcname, pg_size_pretty(pg_tablespace_size(oid)) AS size FROM pg_tablespace
WHERE spcname IN ('ssd_hot_storage', 'hdd_cold_storage'); -- 'pg_default' with hot tablespace on SSD
```

### checking information about chunks: </br>

- to list all details about created chunks: <br>
`SELECT * FROM timescaledb_information.chunks`

- to check the size of each chunk in megabyte for specific table:
```sql
SELECT
	chunk_schema,
	chunk_name,
    table_bytes / (1024 * 1024) AS table_mb,
    index_bytes / (1024 * 1024) AS index_mb,
    toast_bytes / (1024 * 1024) AS toast_mb,
    total_bytes / (1024 * 1024) AS toast_mb
FROM
    chunks_detailed_size('history');
	
```


### Information related to Storage Tiering:
It Operates on **"Cold" Data Only**: The script is explicitly designed to only touch old, inactive chunks. Zabbix server processes are exclusively writing to and reading from the single newest, "hot" chunk. This script will never touch the chunk Zabbix is actively using, so there is no risk of write contention or data corruption

The script does not perform any risky, direct manipulation. It only uses the official, documented `move_chunk` function provided by TimescaleDB, which is built to be transactional and safe. If a move fails for any reason (e.g., disk full), the operation is rolled back cleanly.

**Impact on Zabbix (Writes & Real-time Data):** Zero. While the job is running in the background, Zabbix's ability to write new data or for you to view dashboards of recent data is completely unaffected. This is because those operations use different chunks and different disk I/O paths.

**Impact on Reading old Data**: This is the intentional "performance reduction." After a chunk is moved to the HDD, any Zabbix report or query that needs data from that time period will be slower, as it is reading from a slower disk. This is the entire point and expected trade-off of a hot/cold storage system.

**RECOMMENDATION** <br>
To minimize the I/O impact on the overall system, you should schedule this job to run during off-peak hours (for example, by setting the interval in add_job to '1 day' WITH START TIME '03:00'). This ensures the heavy lifting happens when your Zabbix server is least busy.


#### Chunk Interval and Zabbix `TimeScaleDB.schemasql` file
When the scheduler runs this function, it automatically passes the ID of the job. We don't use it in our code, but it must be there.

Calculation of Memory Consumption and NVPS is required. also the usecase of each Table and row.

```sql
SELECT set_chunk_time_interval('history', INTERVAL '8 hours');
SELECT set_chunk_time_interval('history_uint', INTERVAL '8 hours');
SELECT set_chunk_time_interval('history_str', INTERVAL '8 hours');
SELECT set_chunk_time_interval('history_text', INTERVAL '8 hours');
SELECT set_chunk_time_interval('history_log', INTERVAL '8 hours');
SELECT set_chunk_time_interval('history_bin', INTERVAL '8 hours');
```


---

## Zabbix Servers and Frontend
The Zabbix Server tier is the **core control plane** of the monitoring system.
In this setup, **two Zabbix servers run in High Availability (HA) mode**, sharing a single database backend and coordinating their roles automatically.

### Zabbix Server Nodes
| Hostname      | CPU    | RAM  | Disk  | IP           |
| ------------- | ------ | ---- | ----- | ------------ |
| zabbix-v-srv1 | 4 vCPU | 8 GB | 30 GB | 172.24.24.47 |
| zabbix-v-srv2 | 4 vCPU | 8 GB | 30 GB | 172.24.24.48 |
| zabbix-frontend-srv2 | 4 vCPU | 8 GB | 30 GB | 172.24.24.49 |

At any given time:
- One node is **active**
- The other remains **standby**
- Failover is handled internally by Zabbix HA logic (not by Keepalived)

![zabbix-servers-frontends](./media/zabbix-server-frontend.png)
Image: Zabbix Servers and Frontend Schema


### Installing and Configuring Zabbix Servers (HA Mode)

Zabbix HA relies on:
- A **shared PostgreSQL database**
- Identical configuration on all Zabbix Server nodes
- Proper HA parameters in `zabbix_server.conf`

> Zabbix HA is **not active-active**.
> Only one server processes data at a time; the standby node is hot and ready to take over.


### Package Installation (Both Servers)
Perform the following steps on **both** `zabbix-v-srv1` and `zabbix-v-srv2`.

1. Switch to root:
```bash
sudo -i
```

2. Install the Zabbix repository:
```bash
wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu24.04_all.deb
dpkg -i zabbix-release_latest_7.4+ubuntu24.04_all.deb
apt update
```

3. Install required components:
```bash
apt install zabbix-server-pgsql zabbix-sql-scripts zabbix-agent2 php8.3-pgsql
```


### Zabbix Server Configuration
Edit the configuration file on **each server**:
```bash
vim /etc/zabbix/zabbix_server.conf
```

#### High Availability Parameters
These values **must be unique per node**:
```ini
HANodeName=zabbix_v_srv1
NodeAddress=172.24.24.47:10051
```

On the second server:
```ini
HANodeName=zabbix_v_srv2
NodeAddress=172.24.24.48:10051
```


### Database Configuration
Zabbix connects to PostgreSQL **via the HAProxy virtual IP**, not directly to database nodes.

```ini
DBHost=172.24.24.26
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
DBPort=5432
AllowUnsupportedDBVersions=1
```

> `AllowUnsupportedDBVersions=1` is required when running newer PostgreSQL or TimescaleDB versions than officially listed by Zabbix.


### Basic Performance Tuning (Safe Defaults)
These are **baseline values**, suitable for small-to-medium deployments.
```ini
StartDiscoverers=1
HousekeepingFrequency=1
MaxHousekeeperDelete=2000
```

Notes for beginners:

- Zabbix performance tuning is **workload-dependent**
- Over-tuning early often causes instability
- Discovery and housekeeping workers should be increased only after observing load



#### Start and Verify Zabbix HA
Restart Zabbix Server on **both nodes**:
```bash
systemctl restart zabbix-server
```

On either server, check HA status:
```bash
zabbix_server -R ha_status
```

Expected output example:

```
#  ID                        Name              Address                  Status     Last Access
1. cmd2s1o9p0001fizx3fld4088 zabbix_v_srv1     172.24.24.47:10051       active     1s
2. cmd2s261e0001lnzyq2dg1xsx zabbix_v_srv2     172.24.24.48:10051       standby    3s
```

This confirms:

- HA cluster is formed
- One node is active
- The second node is in hot-standby mode



#### What This Section Intentionally Does *Not* Cover
For clarity and learning flow, this guide postpones:

- Advanced Zabbix server process tuning
- Cache size calculations


Those are best addressed **after data ingestion begins**, when real metrics are available.

---

##  Zabbix Frontend Configuration
By following the previous instructions, the Zabbix frontend is deployed separately from both Zabbix servers and runs on its own dedicated machine.

The Zabbix frontend does not bind permanently to either the primary or secondary Zabbix server. Instead, it determines the active server by querying the Zabbix database.

The frontend automatically detects the active node by reading the relevant settings from the nodes table in the Zabbix database. The node address of the active node is then used as the Zabbix server address.

Ensure that the Zabbix server address:port is not explicitly defined in the frontend configuration file (conf/zabbix.conf.php in the frontend installation directory), as this would prevent automatic failover detection.



### 1. download zabbix packages and apt sources </br>

download zabbix packages **Pay Attention to version you are using**
```sh
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu24.04_all.deb

```

depackage deb files
```sh
`sudo dpkg -i zabbix-release_latest_7.0+ubuntu24.04_all.deb` </br>
```

update apt repository 
```sh
`sudo apt update` </br>
```

download dependencies and zabbix service packages
```sh
`sudo apt install zabbix-frontend-php php8.3-pgsql zabbix-nginx-conf zabbix-agent2` </br>
```


```sh
`sudo apt install zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql` </br>
```


configure zabbix nginx: </br>
`vim /etc/zabbix/nginx` => change `listen port`

then reload nginx and complete the wizard on zabbix web-service frontend. </br>

**NOTE:**: 
> Remember that only database needs to be defined and frontend will find out which server is Active and which is Standby.


---

## TLS Connection Between Zabbix Frontend and Zabbix Server (Zabbix ≥ 7.4)
Starting with Zabbix **7.4**, the frontend can communicate with the Zabbix Server over **mutual TLS**. </br>
In this section, we configure a **self-signed PKI** to secure communication between:
- Zabbix Frontend (PHP)
- Zabbix Server (HA pair)

> This TLS setup **only secures frontend ↔ server communication**.
> It does **not** affect agent, proxy, or database traffic.

For clarity and isolation, the frontend is assumed to run on a **separate machine**, which is strongly recommended.


#### Step 0 – Prepare SSL Working Directory
On the **frontend node**, create a dedicated directory for TLS material:
```bash
sudo mkdir -p /etc/zabbix/ssl
cd /etc/zabbix/ssl
```

#### Step 1 – Create a Local Certificate Authority (CA)
This CA will sign both frontend and server certificates.
```bash
sudo openssl genrsa -out zabbix-ca.key 4096
sudo openssl req -new -x509 -days 3000 \
  -key zabbix-ca.key \
  -out zabbix-ca.crt \
  -subj "/CN=Zabbix-Internal-CA/"
```

> In production environments, this CA should be protected or replaced with an enterprise PKI.


#### Step 2 – Generate and Sign Zabbix **Server** Certificate

```bash
sudo openssl genrsa -out zabbix-server.key 2048

sudo openssl req -new \
  -key zabbix-server.key \
  -out zabbix-server.csr \
  -subj "/CN=zabbix-server/"
```

Sign the server certificate:

```bash
sudo openssl x509 -req -days 3000 \
  -in zabbix-server.csr \
  -CA zabbix-ca.crt \
  -CAkey zabbix-ca.key \
  -CAcreateserial \
  -sha256 \
  -out zabbix-server.crt
```


#### Step 3 – Generate and Sign Zabbix **Frontend** Certificate

```bash
sudo openssl genrsa -out zabbix-frontend.key 2048

sudo openssl req -new \
  -key zabbix-frontend.key \
  -out zabbix-frontend.csr \
  -subj "/CN=zabbix-frontend/"
```

Sign it:
```bash
sudo openssl x509 -req -days 3000 \
  -in zabbix-frontend.csr \
  -CA zabbix-ca.crt \
  -CAkey zabbix-ca.key \
  -CAcreateserial \
  -sha256 \
  -out zabbix-frontend.crt
```


#### Step 4 – Distribute Certificates to Zabbix Servers
Copy **only what is needed** to each Zabbix Server node:

```bash
scp zabbix-server.key zabbix-server.crt zabbix-ca.crt \
  zabbix-admin@172.24.24.47:/tmp

scp zabbix-server.key zabbix-server.crt zabbix-ca.crt \
  zabbix-admin@172.24.24.48:/tmp
```


#### Step 5 – Install Certificates on Zabbix Servers
On **each Zabbix Server node**:
```bash
sudo mkdir -p /etc/zabbix/ssl
sudo mv /tmp/zabbix-* /etc/zabbix/ssl/
```

Set ownership and permissions:
```bash
sudo chown root:zabbix /etc/zabbix/ssl/zabbix-server.{crt,key} /etc/zabbix/ssl/zabbix-ca.crt
sudo chmod 640 /etc/zabbix/ssl/zabbix-server.key
sudo chmod 644 /etc/zabbix/ssl/zabbix-server.crt /etc/zabbix/ssl/zabbix-ca.crt
```


#### Step 6 – Secure Certificates on Zabbix Frontend
On the **frontend server**:

```bash
sudo chown root:www-data /etc/zabbix/ssl/zabbix-frontend.{crt,key}
sudo chmod 640 /etc/zabbix/ssl/zabbix-frontend.key
sudo chmod 644 /etc/zabbix/ssl/zabbix-frontend.crt
```


#### Step 7 – Configure TLS on Zabbix Server
Edit the configuration on **both Zabbix Server nodes**:

```bash
vim /etc/zabbix/zabbix_server.conf
```

Add or modify:
```ini
TLSFrontendAccept=cert
TLSCertFile=/etc/zabbix/ssl/zabbix-server.crt
TLSKeyFile=/etc/zabbix/ssl/zabbix-server.key
TLSCAFile=/etc/zabbix/ssl/zabbix-ca.crt
```

Optional hardening:
```ini
#TLSFrontendCertIssuer=/CN=Zabbix-Internal-CA/
#TLSFrontendCertSubject=/CN=zabbix-frontend/
```

Restart the server:
```bash
sudo systemctl restart zabbix-server
```


#### Step 8 – Configure TLS on Zabbix Frontend
If using the **web installer**, this can be configured there.
For an **existing installation**, edit:

```bash
vim /etc/zabbix/web/zabbix.conf.php
```

Add:
```php
$ZBX_SERVER_TLS['ACTIVE'] = '1';
$ZBX_SERVER_TLS['CA_FILE'] = '/etc/zabbix/ssl/zabbix-ca.crt';
$ZBX_SERVER_TLS['KEY_FILE'] = '/etc/zabbix/ssl/zabbix-frontend.key';
$ZBX_SERVER_TLS['CERT_FILE'] = '/etc/zabbix/ssl/zabbix-frontend.crt';
```

Reload web services if needed (e.g., PHP-FPM / Nginx).


#### Verification
On Zabbix Server nodes:

```bash
tail -f /var/log/zabbix/zabbix_server.log
```

Successful TLS negotiation will appear **without fallback to plaintext**.


---

## Zabbix Proxy Configuration (PostgreSQL Backend + Dedicated Storage)

Each Zabbix Proxy maintains its **own local database** to buffer data when the Zabbix Server is unavailable.
In this design:

- The proxy database runs **locally on the proxy host**
- No dedicated DB machine is used
- A **separate disk or partition** is allocated exclusively for proxy data
- PostgreSQL and proxy processes are tuned for write-heavy workloads
- Zabbix Proxies can be group in Zabbix Frontend. [Follow Proxy Load Balancing](https://www.zabbix.com/documentation/current/en/manual/distributed_monitoring/proxies/ha) and [Proxy Group](https://www.zabbix.com/documentation/current/en/manual/web_interface/frontend_sections/administration/proxy_groups)

> Proxy databases do **not** require HA. Simplicity and fast local I/O are more important than redundancy here.

![Zabbix-Proxy-Cluster](./media/proxy-cluster.png)
Image: Zabbix Proxy Cluster



### Preparing Disk Partition for Proxy Database
Assuming the additional disk is `/dev/sdb`.
Adjust device names if your layout differs.

#### 1. Create and Mount Logical Volume
```bash
sudo pvs
sudo vgs
```

Create a logical volume using all free space:
```bash
sudo lvcreate -l +100%FREE -n proxy_db_lv ubuntu-vg
```

Format and mount:
```bash
sudo mkfs.ext4 /dev/mapper/ubuntu--vg-proxy_db_lv
sudo mkdir -p /mnt/proxy_db
sudo mount /dev/mapper/ubuntu--vg-proxy_db_lv /mnt/proxy_db
```

Persist the mount:
```bash
echo "/dev/mapper/ubuntu--vg-proxy_db_lv /mnt/proxy_db ext4 defaults 0 0" | sudo tee -a /etc/fstab
mount -a
df -h
```


#### 2. Install PostgreSQL 17 on Proxy Host
```bash
sudo apt update
```

Add PostgreSQL repository:
```bash
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
  | sudo tee /etc/apt/sources.list.d/pgdg.list

curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
```

Install PostgreSQL:
```bash
sudo apt update
sudo apt install postgresql-17
```


#### PostgreSQL Tuning for Proxy Workload

Add or adjust these values in:
```
/etc/postgresql/17/main/postgresql.conf
```

```ini
shared_buffers = 2GB
effective_cache_size = 4GB
maintenance_work_mem = 512MB
checkpoint_completion_target = 0.9
random_page_cost = 4
default_statistics_target = 100
effective_io_concurrency = 2
work_mem = 32MB
huge_pages = off

max_worker_processes = 8
max_parallel_workers = 8
max_parallel_maintenance_workers = 2
max_parallel_workers_per_gather = 4

autovacuum = on
autovacuum_max_workers = 4
```

Restart PostgreSQL:
```bash
sudo systemctl restart postgresql
```


### 3. Create Tablespace for Proxy Database

#### Prepare Directory and Permissions
```bash
sudo mkdir -p /mnt/proxy_db/pgdata
sudo chown postgres:postgres /mnt/proxy_db
sudo chmod 770 /mnt/proxy_db
```

> Tablespaces **must always be owned by postgres**.
> Using the `zabbixproxy` OS user here is incorrect and unsafe.



#### Create Tablespace

```bash
sudo -u postgres psql
```

```sql
CREATE TABLESPACE proxy_storage
LOCATION '/mnt/proxy_db/pgdata';
```

Verify:
```sql
\db+
```


#### 4. Create Proxy Database and User

Create database user:
```bash
sudo -u postgres createuser zabbixproxy
sudo -u postgres psql
```

```sql
ALTER USER zabbixproxy WITH PASSWORD 'Pr0x7G4T3';
```

Create database on the dedicated tablespace:
```bash
sudo -u postgres createdb \
  -O zabbixproxy \
  --tablespace=proxy_storage \
  zabbix_proxy
```

Grant tablespace permissions:
```sql
GRANT ALL PRIVILEGES ON TABLESPACE proxy_storage TO zabbixproxy;
```


#### 5. Install Zabbix Proxy Packages (PostgreSQL)

be advised that zabbix proxy version must match with your own Zabbix Server Version. in this case it is 7.4

```bash
wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_latest_7.4+ubuntu24.04_all.deb
sudo apt update
```

Install proxy components:
```bash
sudo apt install zabbix-proxy-pgsql zabbix-sql-scripts
```

Import schema:

```bash
cat /usr/share/zabbix/sql-scripts/postgresql/proxy.sql \
  | sudo -u postgres psql zabbix_proxy
```


#### 6. Configure Zabbix Proxy

Edit:
```bash
sudo vim /etc/zabbix/zabbix_proxy.conf
```

Example Configuration (Active Proxy):
```ini
DBHost=127.0.0.1
DBPort=5432
DBName=zabbix_proxy
DBUser=zabbixproxy
DBPassword=Pr0x7G4T3

Hostname=dcimproxy-mgt-srv1
ListenIP=0.0.0.0
ListenPort=10051

ProxyMode=Active
Server=172.24.24.47:10051;172.24.24.48:10051
```

> **Active proxies** use `;`
> **Passive proxies** use `,`
> This is not cosmetic — it affects failover behavior.


#### 7. Register Proxy in Zabbix Frontend

In the UI:
```
Administration → Proxies → Create proxy
```

Configure:
- Proxy name (must match `Hostname`)
- Mode (Active / Passive)
- Proxy address (IP or DNS)



#### 8. Secure Proxy ↔ Server Communication with PSK

1. Generate PSK

```bash
sudo mkdir -p /etc/zabbix/encryption
sudo openssl rand -hex 32 > /etc/zabbix/encryption/proxy.psk
sudo chown zabbix:zabbix /etc/zabbix/encryption/proxy.psk
sudo chmod 400 /etc/zabbix/encryption/proxy.psk
```

2. Configure Proxy TLS

```ini
TLSConnect=psk
TLSAccept=psk
TLSPSKFile=/etc/zabbix/encryption/proxy.psk
TLSPSKIdentity=proxy_psk001
```

3. Configure TLS in Frontend

```
Administration → Proxies → Encryption
```

- Enable **PSK**
- Set identity and key
- Disable “No encryption”


#### 9. Start and Verify Proxy
```bash
sudo systemctl restart zabbix-proxy
journalctl -u zabbix-proxy -f
```

Proxy should appear as **Available** in the frontend within seconds.



---

## Installing and Configuring Grafana (Co-located with Zabbix Frontend)

In this setup, **Grafana runs on the same machine as the Zabbix frontend**.
Grafana will visualize Zabbix data using **two possible paths**:

1. Zabbix API (official, supported, safer)
2. Direct PostgreSQL access (faster, but advanced and fragile)

We will install Grafana first, then explain **when and how** to use each method.



### Important Design Note (Read First)

Reading **directly from the Zabbix database** can:
- Reduce load on the Zabbix API
- Improve dashboard performance for large datasets

However, it also:
- Couples Grafana to Zabbix’s internal schema
- Can break after Zabbix upgrades
- Is **not officially supported** for all queries

**Recommendation:**
- Use **API mode first**
- Enable **Direct DB mode only for heavy dashboards**

This section reflects that order.



### 1. Install Grafana OSS

#### 1.1 Install Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https software-properties-common wget
```


#### 1.2 Add Grafana GPG Key and Repository

```bash
sudo mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key \
  | gpg --dearmor \
  | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
```

Add **stable** repository (beta is not recommended for production):
```bash
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
  | sudo tee /etc/apt/sources.list.d/grafana.list
```

Update package list and install:
```bash
sudo apt-get update
sudo apt-get install grafana
```


#### 1.3 Start and Enable Grafana
```bash
sudo systemctl enable grafana-server
sudo systemctl restart grafana-server
```

Grafana listens on:
```
http://<frontend-ip>:3000
```

Default credentials:
- **User:** admin
- **Password:** admin

You will be forced to change it on first login.


### 2. Install Zabbix Plugin for Grafana (API Mode)
This plugin is required **even if you plan to use Direct DB later**.

#### 2.1 Install Plugin via CLI
```bash
grafana-cli plugins install alexanderzobnin-zabbix-app
sudo systemctl restart grafana-server
```

#### 2.2 Enable Plugin in Grafana UI
Navigate to:
```
Administration → Plugins and data → Plugins → Zabbix
```

Enable the plugin and follow the built-in configuration wizard. </br>
At this point, Grafana can already visualize Zabbix data using the **API only**.


### 3. (Optional) Direct Database Access for Better Performance

This step is **optional and advanced**. Only proceed if:
- You understand PostgreSQL permissions
- You accept schema-level coupling
- You have large dashboards with performance issues

Reference: </br>
[Grafana Zabbix Plugin – Direct DB Mode](https://grafana.com/docs/plugins/alexanderzobnin-zabbix-app/latest/configuration/direct-db-datasource/)


### 4. Create a Read-Only PostgreSQL User for Grafana

#### 4.1 Create User
Run on the **Zabbix PostgreSQL server**:

```bash
sudo -u postgres psql
```

```sql
CREATE USER grafana_dcim WITH PASSWORD 'strong_password';
```


#### 4.2 Grant Read-Only Access

```sql
GRANT CONNECT ON DATABASE zabbix TO grafana_dcim;
\c zabbix

GRANT USAGE ON SCHEMA public TO grafana_dcim;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana_dcim;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO grafana_dcim;
```


### 5. Add PostgreSQL Data Source in Grafana

In Grafana UI:

```
Connections → Data Sources → PostgreSQL
```

### Required Fields

**Connection**
- Host: `postgres-vip-or-hostname:5432`
- Database: `zabbix`
- User: `grafana_dcim`
- Password: `<password>`

**TLS**
- Use TLS if your DB cluster is encrypted
- Otherwise leave disabled (internal network only)

Save & Test.


### 6. Enable Direct DB Mode in Zabbix Plugin

Go to:
```
Connections → Data Sources → Zabbix
```

Configure:
- Enable **Direct DB Connection**
- Select the PostgreSQL datasource you just created
- Keep API credentials configured as fallback

This hybrid mode allows:
- Metadata via API
- Heavy history queries via SQL


#### Critical Caveats (Do Not Skip)
- Zabbix upgrades **can change DB schema**
- Always test Grafana dashboards after upgrades
- Never allow Grafana write access to Zabbix DB



## Conclusion

This guide presented a **production-oriented Zabbix monitoring architecture** designed for scale, resiliency, and long-term operability rather than minimal installation effort. Each major component—Zabbix Server HA, PostgreSQL-backed proxies, TLS-secured frontend communication, and Grafana integration—was introduced with explicit design intent, not as isolated features.

Several core principles shaped the architecture:

- **High availability is enforced at the control plane**, not assumed.
  Zabbix Server HA, database clustering, and frontend auto-discovery ensure continuity without manual intervention.

- **Storage is treated as a first-class design variable**, not an afterthought.
  Partitioning, tablespaces, and hot/cold data placement acknowledge that monitoring data grows predictably and aggressively.

- **Security is explicit and layered**, not implicit.
  TLS between frontend and server, PSK-secured proxies, and least-privilege database users reduce blast radius while remaining operationally manageable.

- **Performance optimizations are deliberate and scoped**, not global.
  Direct database access from Grafana is enabled where it delivers measurable value, while API-based access remains the default and safest integration path.

This document does **not promote a universal blueprint**. The choices described here reflect trade-offs between operational complexity, performance, maintainability, and supportability. Different environments may reasonably arrive at different conclusions—and that is expected.


### Community Contributions

This guide is intended to be **iterative rather than static**.
Monitoring platforms evolve, workloads change, and better patterns emerge over time.

Contributions from the community are not only welcome but encouraged—whether in the form of:

- corrections or clarifications,
- alternative architectural approaches,
- tuning results from real-world deployments,
- or lessons learned under scale or failure conditions.


Constructive feedback and practical improvements help ensure this document remains accurate, relevant, and grounded in operational reality.


### Future Sections

The following sections will be added to extend this guide:

- **Acknowledgments**
  Highlighting upstream Zabbix documentation, community discussions, and tools that influenced the design decisions.

- **Tuning and Optimization Notes**
  Covering observed behavior and trade-offs related to:

  - NVPS growth
  - PostgreSQL write amplification and vacuum behavior
  - Housekeeping efficiency
  - Proxy buffering and backlog handling
  - Grafana query patterns and cache effectiveness



### Final Note
Monitoring systems are infrastructure about infrastructure.
If they fail silently, everything else follows.

The objective of this guide is not merely to deploy Zabbix, but to **make its behavior predictable under pressure**, observable during failure, and maintainable as scale increases.

Community input is a key part of achieving that goal.



## Contact & Collaboration

For questions, discussions, or contributions related to this guide, you can reach me through the following channels:

* **LinkedIn**
  [https://www.linkedin.com/in/mohammadreza-tatlari-11922121b/](https://www.linkedin.com/in/mohammadreza-tatlari-11922121b/)


* **GitHub**
  [https://github.com/Mohammadreza-Tatlari](https://github.com/Mohammadreza-Tatlari)


* **Email**
  [mohammadreza.tatlari8@gmail.com](mailto:mohammadreza.tatlari8@gmail.com)



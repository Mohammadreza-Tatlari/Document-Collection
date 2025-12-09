# Ceph Cluster Complete Deployment Guide
## 3-Node Production Setup
**Ceph Version:** 19.2.3 (Squid)


## Infrastructure Overview

### Cluster Nodes

| Hostname | IP Address | Role | RAM | OS Disk | Ceph Disk |
|----------|------------|------|-----|---------|-----------|
| ceph-storage-1 | 172.31.11.53 | Mon, Mgr, OSD | 4GB | 50GB (sda) | 100GB (sdb) (not partioned) |
| ceph-storage-2 | 172.31.11.54 | Mon, Mgr, OSD | 4GB | 50GB (sda) | 100GB (sdb) (not partioned) |
| ceph-storage-3 | 172.31.11.55 | Mon, OSD | 4GB | 50GB (sda) | 100GB (sdb) (not partioned) |

### Network Configuration

```
Network: 172.31.11.0/24
```

### Final Cluster Status

```bash
root@ceph-storage-1:~# ceph -s
  cluster:
    id:     6c44eb7e-cde9-11f0-8900-bc2411bc45d1
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum ceph-storage-1,ceph-storage-3,ceph-storage-2
    mgr: ceph-storage-1.zkipis(active), standbys: ceph-storage-2.ygbyjd
    osd: 3 osds: 3 up, 3 in
 
  data:
    pools:   3 pools, 65 pgs
    objects: 8 objects, 577 KiB
    usage:   94 MiB used, 300 GiB / 300 GiB avail
    pgs:     65 active+clean
```

---

## Prerequisites and Preparation

### Step 1: Verify Hardware on All Nodes

Run on **ceph-storage-1, ceph-storage-2, ceph-storage-3**:

- verify that each node is in your defined ip range
```bash
# Check network configuration
root@ceph-storage-1:~# ip -br -c a 
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             172.31.11.53/24 fe80::be24:11ff:febc:45d1/64
```


- disable swap on all nodes. because ceph is designed to manage memory and to ensure predictable behavior. we don't want it to start swaping. </br>
`swapoff -a` </br>
> to make these changes permanent edit `fstab` file:
`vim /etc/fstab` -> comment out the lines related to swapping


- verify memory capacity and swap of each node
```bash
# Check memory
root@ceph-storage-1:~# free -h
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       513Mi       2.5Gi       5.1Mi       1.1Gi       3.3Gi
Swap:             0B          0B          0B
```


- check block storage list on each node
```bash
# Check disks
root@ceph-storage-1:~# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda       8:0    0   50G  0 disk 
├─sda1    8:1    0   49G  0 part /
├─sda14   8:14   0    4M  0 part 
├─sda15   8:15   0  106M  0 part /boot/efi
└─sda16 259:0    0  913M  0 part /boot
sdb       8:16   0  100G  0 disk 
sr0      11:0    1    4M  0 rom
```

**Important:** `/dev/sdb` must be empty and unformatted on all nodes.


### Step 2: Update System (All Nodes)

```bash
# Update package lists and upgrade
apt update && apt upgrade -y

# Install basic dependencies
apt install -y python3 python3-pip curl lvm2 chrony
```

### Step 3: Configure Time Synchronization (All Nodes)

```bash
# Enable and start chrony
systemctl enable chrony
systemctl start chrony
systemctl status chrony

# Verify time sync
chronyc tracking
```

**Output example:**
```
Reference ID    : C0A80001 (192.168.0.1)
Stratum         : 3
Ref time (UTC)  : Sun Nov 30 14:00:00 2025
System time     : 0.000000000 seconds fast of NTP time
Last offset     : +0.000000000 seconds
```

### Step 4: Configure Hostname Resolution (All Nodes)

```bash
# Add entries to /etc/hosts
cat >> /etc/hosts << EOF
172.31.11.53 ceph-storage-1
172.31.11.54 ceph-storage-2
172.31.11.55 ceph-storage-3
EOF

# Verify resolution
ping -c 2 ceph-storage-1
ping -c 2 ceph-storage-2
ping -c 2 ceph-storage-3
```

<!-- ### Step 5: Configure SSH Access (On ceph-storage-1)

```bash
# Generate SSH key on ceph-storage-1 (admin node)
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519

# Copy SSH key to all nodes (including itself)
ssh-copy-id root@172.31.11.53
ssh-copy-id root@172.31.11.54
ssh-copy-id root@172.31.11.55

# Also copy to hostnames
ssh-copy-id root@ceph-storage-1
ssh-copy-id root@ceph-storage-2
ssh-copy-id root@ceph-storage-3

# Test passwordless SSH
ssh root@ceph-storage-2 hostname
ssh root@ceph-storage-3 hostname
```

**Expected output:**
```
ceph-storage-2
ceph-storage-3
```

--- -->



### install Cephadm packages on First Node (ceph-1)
1. install cephadm packages
`apt install cephadm`

2. Bootstrap Ceph Cluster (On ceph-storage-1) </br>
Bootstrap creates the initial Ceph cluster with one monitor and one manager.
```bash
# Bootstrap the cluster
cephadm bootstrap --mon-ip 172.31.11.152 --cluster-network 172.31.11.0/24 --initial-dashboard-user admin --initial-dashboard-password Aa123456
```

3. verify the containers running: </br>
```bash
docker ps -a
```



### Step 5: Copy ceph ssh public key to other nodes </br>
`sudo vim /etc/ssh/sshd_config.d/60-cloudimg-settings.conf`
`sudo systemctl restart ssh`
ceph public key is present in `/etc/ceph/ceph.pub` and we need to copy it to the servers. 
`ssh-copy-id -f -i /etc/ceph/ceph.pub ubuntu@172.31.11.152`


#### Authorize ssh public keys for root (all nodes)
1. create a .ssh directory in root of each node as follow:
`sudo mkdir -p /root/.ssh; sudo chmod 700 /root/.ssh`
`tail -1 /home/ubuntu/.ssh/authorized_keys | sudo tee -a /root/.ssh/authorized_keys` => it is going to copy ubuntu user newly added authorized key which for ceph to root's authorized keys.



### Install Docker (All Nodes)
[Docker Installation on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

### Enable CEPH CLI 
The `cephadm shell` command launches a bash shell in a container with all of the Ceph packages installed. By default, if configuration and keyring files are found in /etc/ceph on the host, they are passed into the container environment so that the shell is fully functional. 
- create ceph package container:
```sh
cephadm shell
```

- verify it (this command is being executed inside ceph shell container):
```sh
ceph -s
```


### Add Hosts to Cluster
To add each new host to the cluster, we need to perform `ceph orch` command inside the **ceph shell** created by `cephadm shell`:

- list all currently added host to ceph cluster
```sh
ceph orch host ls
```

**note:**
> By default, a `ceph.conf` file and a copy of the `client.admin` keyring are maintained in `/etc/ceph` on all hosts that have the `_admin` label. This label is initially applied only to the bootstrap host. We recommend that one or more other hosts be given the `_admin` label so that the Ceph CLI (for example, via `cephadm shell`) is easily accessible on multiple hosts.


```sh
ceph orch host add ceph-v-srv2 172.31.11.153
ceph orch host add ceph-v-srv3 172.31.11.154
```


### devices in cluster
List devices on a host
- `ceph orch device ls`

Create OSD daemon(s) on all available devices
- `ceph orch apply osd --all_available_devices`

## Initial Setup



```bash
# Check available Ceph versions
apt-cache policy ceph
```

**Output:**
```
ceph:
  Installed: (none)
  Candidate: 19.2.1-0ubuntu0.24.04.2
  Version table:
     19.2.1-0ubuntu0.24.04.2 500
        500 http://archive.ubuntu.com/ubuntu noble-updates/main amd64 Packages
     19.2.0-git20240301.4c76c50-0ubuntu6 500
        500 http://archive.ubuntu.com/ubuntu noble/main amd64 Packages
```

**Ceph 19.2.1 (Squid) is available!**


---

## Ceph Bootstrap

### Step 8: Bootstrap Ceph Cluster (On ceph-storage-1)

Bootstrap creates the initial Ceph cluster with one monitor and one manager.

```bash
# Bootstrap the cluster
cephadm bootstrap --mon-ip 172.31.11.53
```

**Bootstrap process output:**
```
Creating directory /etc/ceph for ceph.conf
Verifying podman|docker is present...
Verifying lvm2 is present...
Verifying time synchronization is in place...
Unit chrony.service is enabled and running
Repeating the final host check...
docker (/usr/bin/docker) is present
systemctl is present
lvcreate is present
Unit chrony.service is enabled and running
Host looks OK
Cluster fsid: 6c44eb7e-cde9-11f0-8900-bc2411bc45d1
Verifying IP 172.31.11.53 port 3300 ...
Verifying IP 172.31.11.53 port 6789 ...
Mon IP `172.31.11.53` is in CIDR network `172.31.11.0/24`
Internal network (--cluster-network) has not been provided, OSD replication will default to the public_network
Pulling container image quay.io/ceph/ceph:v19...
Ceph version: ceph version 19.2.3 (c92aebb279828e9c3c1f5d24613efca272649e62) squid (stable)
Extracting ceph user uid/gid from container image...
Creating initial keys...
Creating initial monmap...
Creating mon...
Waiting for mon to start...
Waiting for mon...
mon is available
Assimilating anything we can from ceph.conf...
Generating new minimal ceph.conf...
Restarting the monitor...
Setting public_network to 172.31.11.0/24 in mon config section
Wrote config to /etc/ceph/ceph.conf
Wrote keyring to /etc/ceph/ceph.client.admin.keyring
Creating mgr...
Verifying port 0.0.0.0:9283 ...
Verifying port 0.0.0.0:8765 ...
Verifying port 0.0.0.0:8443 ...
Waiting for mgr to start...
mgr is available
Enabling cephadm module...
Waiting for the mgr to restart...
Setting orchestrator backend to cephadm...
Generating ssh key...
Wrote public SSH key to /etc/ceph/ceph.pub
Adding key to root@localhost authorized_keys...
Adding host ceph-storage-1...
Deploying mon service with default placement...
Deploying mgr service with default placement...
Deploying crash service with default placement...
Deploying ceph-exporter service with default placement...
Deploying prometheus service with default placement...
Deploying grafana service with default placement...
Deploying node-exporter service with default placement...
Deploying alertmanager service with default placement...
Enabling the dashboard module...
Generating a dashboard self-signed certificate...
Creating initial admin user...
Fetching dashboard port number...

Ceph Dashboard is now available at:

             URL: https://ceph-storage-1:8443/
            User: admin
        Password: x81x5qzb6z

Enabling client.admin keyring and conf on hosts with "admin" label
Saving cluster configuration to /var/lib/ceph/6c44eb7e-cde9-11f0-8900-bc2411bc45d1/config directory

Bootstrap complete.
```

**🎉 Initial cluster created!**

### Step 9: Install Ceph CLI Tools (On ceph-storage-1)

```bash
# Install ceph-common package for CLI commands
cephadm install ceph-common

# Verify installation
ceph -v
```

**Output:**
```
ceph version 19.2.1 (9efac4a81335940925dd17dbf407bfd6d3860d28) squid (stable)
```

```bash
# Check initial cluster status
ceph status
```

**Output:**
```
root@ceph-storage-1:~# ceph status
  cluster:
    id:     6c44eb7e-cde9-11f0-8900-bc2411bc45d1
    health: HEALTH_WARN
            OSD count 0 < osd_pool_default_size 3
 
  services:
    mon: 1 daemons, quorum ceph-storage-1 (age 24m)
    mgr: ceph-storage-1.zkipis(active, since 18m)
    osd: 0 osds: 0 up, 0 in
 
  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   0 B used, 0 B / 0 B avail
```

**Note:** HEALTH_WARN is expected - no OSDs yet!

---

## Cluster Expansion

### Step 10: Copy SSH Keys of ceph to other nodes (On ceph-storage-1)

Ceph needs SSH access to manage other nodes.

```bash
# Ensure SSH works to localhost
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

# Test SSH to localhost
ssh root@localhost hostname
ssh root@ceph-storage-1 hostname
```

**Output:**
```
ceph-storage-1
ceph-storage-1
```

```bash
# Copy Ceph's public key to other nodes
ssh-copy-id -f -i /etc/ceph/ceph.pub root@172.31.11.54
ssh-copy-id -f -i /etc/ceph/ceph.pub root@172.31.11.55
```

### Step 11: Add ceph-storage-2 to Cluster

```bash
# Add the host
ceph orch host add ceph-storage-2 172.31.11.54
```

**Output:**
```
Added host 'ceph-storage-2' with addr '172.31.11.54'
```

```bash
# Verify host was added
ceph orch host ls
```

**Output:**
```
root@ceph-storage-1:~# ceph orch host ls
HOST             ADDR          LABELS  STATUS  
ceph-storage-1   172.31.11.53  _admin          
ceph-storage-2   172.31.11.54                  
2 hosts in cluster
```

### Step 12: Add ceph-storage-3 to Cluster

```bash
# Add the host
ceph orch host add ceph-storage-3 172.31.11.55
```

**Output:**
```
Added host 'ceph-storage-3' with addr '172.31.11.55'
```

```bash
# Verify all hosts
ceph orch host ls
```

**Output:**
```
root@ceph-storage-1:~# ceph orch host ls
HOST             ADDR          LABELS  STATUS  
ceph-storage-1   172.31.11.53  _admin          
ceph-storage-2   172.31.11.54                  
ceph-storage-3   172.31.11.55                  
3 hosts in cluster
```

### Step 13: Deploy Monitors on All Nodes

Monitors manage the cluster state. We need 3 for quorum (high availability).

```bash
# Deploy monitors on all three nodes
ceph orch apply mon --placement="ceph-storage-1,ceph-storage-2,ceph-storage-3"
```

**Output:**
```
Scheduled mon update...
```

```bash
# Wait 60 seconds for deployment
sleep 60

# Check monitor deployment
ceph orch ps --daemon-type mon
```

**Output:**
```
root@ceph-storage-1:~# ceph orch ps --daemon-type mon
NAME                HOST             PORTS  STATUS         REFRESHED  AGE  MEM USE  MEM LIM  VERSION  IMAGE ID      CONTAINER ID  
mon.ceph-storage-1  ceph-storage-1          running (67m)   101s ago  67m    55.9M    2048M  19.2.3   aade1b12b8e6  50392717f2b0  
mon.ceph-storage-2  ceph-storage-2          running (4m)     30s ago   4m    29.7M    2048M  19.2.3   aade1b12b8e6  4a21d17c2a78  
mon.ceph-storage-3  ceph-storage-3          running (4m)     29s ago   4m    29.1M    2048M  19.2.3   aade1b12b8e6  32237118309e
```

```bash
# Check monitor quorum
ceph mon stat
```

**Output:**
```
root@ceph-storage-1:~# ceph mon stat
e3: 3 mons at {ceph-storage-1=[v2:172.31.11.53:3300/0,v1:172.31.11.53:6789/0],ceph-storage-2=[v2:172.31.11.54:3300/0,v1:172.31.11.54:6789/0],ceph-storage-3=[v2:172.31.11.55:3300/0,v1:172.31.11.55:6789/0]} removed_ranks: {} disallowed_leaders: {}, election epoch 14, leader 0 ceph-storage-1, quorum 0,1,2 ceph-storage-1,ceph-storage-3,ceph-storage-2
```

**3 monitors in quorum!**

### Step 14: Deploy Managers

Managers handle cluster management tasks. Deploy 2 for redundancy.

```bash
# Deploy managers on storage-1 and storage-2
ceph orch apply mgr --placement="ceph-storage-1,ceph-storage-2"
```

```bash
# Check manager status
ceph orch ps --daemon-type mgr
ceph mgr stat
```

**Output:**
```
mgr: ceph-storage-1.zkipis(active, since 79m), standbys: ceph-storage-2.ygbyjd
```

**Active manager on storage-1, standby on storage-2!**

---

## Storage Configuration

### Step 15: Check Available Disks

```bash
# List available storage devices on all nodes
ceph orch device ls
```

**Output:**
```
root@ceph-storage-1:~# ceph orch device ls
HOST             PATH      TYPE  DEVICE ID                   SIZE  AVAILABLE  REFRESHED  REJECT REASONS                               
ceph-storage-1   /dev/sdb  hdd   QEMU_HARDDISK_drive-scsi1   100G  Yes        20m ago                                                 
ceph-storage-1   /dev/sr0  hdd   QEMU_DVD-ROM_QM00003       4096k  No         20m ago    Has a FileSystem, Insufficient space (<5GB)  
ceph-storage-2   /dev/sdb  hdd   QEMU_HARDDISK_drive-scsi1   100G  Yes        9m ago                                                  
ceph-storage-2   /dev/sr0  hdd   QEMU_DVD-ROM_QM00003       4096k  No         9m ago     Has a FileSystem, Insufficient space (<5GB)  
ceph-storage-3   /dev/sdb  hdd   QEMU_HARDDISK_drive-scsi1   100G  Yes        6m ago                                                  
ceph-storage-3   /dev/sr0  hdd   QEMU_DVD-ROM_QM00003       4096k  No         6m ago     Has a FileSystem, Insufficient space (<5GB)
```

**Perfect! All three /dev/sdb disks (100GB) are available.**

### Step 16: Deploy OSDs (Object Storage Daemons)

OSDs are the actual storage daemons that store data.

```bash
# Automatically deploy OSDs on all available devices
ceph orch apply osd --all-available-devices
```

**Output:**
```
Scheduled osd.all-available-devices update...
```

```bash
# Watch OSD deployment (takes 5-10 minutes)
watch -n 5 'ceph orch ps --daemon-type osd'
```

Press Ctrl+C when you see 3 OSDs running.

**Final output:**
```
root@ceph-storage-1:~# ceph orch ps --daemon-type osd
NAME   HOST             PORTS  STATUS        REFRESHED  AGE  MEM USE  MEM LIM  VERSION  IMAGE ID      CONTAINER ID
osd.0  ceph-storage-1          running (6m)     5m ago   6m    38.4M    4096M  19.2.3   aade1b12b8e6  41fe4d19b848
osd.1  ceph-storage-3          running (6m)     5m ago   6m    30.5M    4096M  19.2.3   aade1b12b8e6  b110b5405282
osd.2  ceph-storage-2          running (6m)     5m ago   6m    34.5M    4096M  19.2.3   aade1b12b8e6  031e5995bd43
```

```bash
# Check OSD tree (shows distribution)
ceph osd tree
```

**Output:**
```
root@ceph-storage-1:~# ceph osd tree
ID  CLASS  WEIGHT   TYPE NAME                 STATUS  REWEIGHT  PRI-AFF
-1         0.29306  root default                                      
-3         0.09769      host ceph-storage-1                           
 0    hdd  0.09769          osd.0                 up   1.00000  1.00000
-5         0.09769      host ceph-storage-2                           
 2    hdd  0.09769          osd.2                 up   1.00000  1.00000
-7         0.09769      host ceph-storage-3                           
 1    hdd  0.09769          osd.1                 up   1.00000  1.00000
```

**3 OSDs deployed, one per node!**

```bash
# Check final cluster status
ceph -s
```

**Output:**
```
root@ceph-storage-1:~# ceph -s
  cluster:
    id:     6c44eb7e-cde9-11f0-8900-bc2411bc45d1
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum ceph-storage-1,ceph-storage-3,ceph-storage-2 (age 23m)
    mgr: ceph-storage-1.zkipis(active, since 79m), standbys: ceph-storage-2.ygbyjd
    osd: 3 osds: 3 up (since 6m), 3 in (since 8m)
 
  data:
    pools:   1 pools, 1 pgs
    objects: 2 objects, 577 KiB
    usage:   82 MiB used, 300 GiB / 300 GiB avail
    pgs:     1 active+clean
```

**Cluster is HEALTH_OK! Ready for production use!**

### Step 17: Verify Disk Usage

```bash
# Check how disks are being used
lsblk
```

**Output:**
```
root@ceph-storage-1:~# lsblk
NAME                                                          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                                                             8:0    0   50G  0 disk 
├─sda1                                                          8:1    0   49G  0 part /
├─sda14                                                         8:14   0    4M  0 part 
├─sda15                                                         8:15   0  106M  0 part /boot/efi
└─sda16                                                       259:0    0  913M  0 part /boot
sdb                                                             8:16   0  100G  0 disk 
└─ceph--f0cc1d07--eda6--4f65--acd3--5679151a2f35-osd--block--29a2b9fd--9fce--4854--860e--95ef92d9b4f8
                                                              252:0    0  100G  0 lvm  
sr0                                                            11:0    1    4M  0 rom
```

**Note:** `/dev/sdb` is now managed by Ceph using LVM.

### Step 18: Create Storage Pools

Pools are logical storage containers.

```bash
# Create RBD pool for block storage (32 PGs)
ceph osd pool create rbd 32 32
ceph osd pool application enable rbd rbd
rbd pool init rbd
```

**Output:**
```
pool 'rbd' created
enabled application 'rbd' on pool 'rbd'
```

```bash
# Create general-purpose pool
ceph osd pool create mypool 32 32
ceph osd pool application enable mypool rbd
```

**Output:**
```
pool 'mypool' created
enabled application 'rbd' on pool 'mypool'
```

```bash
# List all pools
ceph osd pool ls detail
```

**Output:**
```
root@ceph-storage-1:~# ceph osd pool ls detail
pool 1 '.mgr' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 1 pgp_num 1 autoscale_mode on last_change 21 flags hashpspool stripe_width 0 pg_num_max 32 pg_num_min 1 application mgr read_balance_score 3.00

pool 2 'rbd' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 28 flags hashpspool,selfmanaged_snaps stripe_width 0 application rbd read_balance_score 1.31

pool 3 'mypool' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 32 flags hashpspool stripe_width 0 application rbd read_balance_score 1.13
```

```bash
# Check storage usage
ceph df
```

**Output:**
```
root@ceph-storage-1:~# ceph df
--- RAW STORAGE ---
CLASS     SIZE    AVAIL    USED  RAW USED  %RAW USED
hdd    300 GiB  300 GiB  94 MiB    94 MiB       0.03
TOTAL  300 GiB  300 GiB  94 MiB    94 MiB       0.03
 
--- POOLS ---
POOL    ID  PGS   STORED  OBJECTS     USED  %USED  MAX AVAIL
.mgr     1    1  577 KiB        2  1.7 MiB      0     95 GiB
rbd      2   32     19 B        2   12 KiB      0     95 GiB
mypool   3   32      0 B        0      0 B      0     95 GiB
```

**Storage Summary:**
- **Total Raw:** 300 GiB (3 x 100GB disks)
- **Usable per pool:** ~95 GiB (with 3x replication)
- **Current usage:** 94 MiB (nearly empty)

---

## RBD Block Storage

RBD (RADOS Block Device) provides block storage similar to traditional SAN/iSCSI.

### Step 19: Create RBD Image

```bash
# Create a 10GB block device
rbd create testimage --size 10G --pool rbd
```

```bash
# List RBD images
rbd ls -p rbd
```

**Output:**
```
root@ceph-storage-1:~# rbd ls -p rbd
testimage
```

```bash
# Get detailed image information
rbd info testimage -p rbd
```

**Output:**
```
root@ceph-storage-1:~# rbd info testimage -p rbd
rbd image 'testimage':
        size 10 GiB in 2560 objects
        order 22 (4 MiB objects)
        snapshot_count: 0
        id: 3885ce7932ef
        block_name_prefix: rbd_data.3885ce7932ef
        format: 2
        features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
        op_features: 
        flags: 
        create_timestamp: Sun Nov 30 14:15:41 2025
        access_timestamp: Sun Nov 30 14:15:41 2025
        modify_timestamp: Sun Nov 30 14:15:41 2025
```

```bash
# Check RBD disk usage
rbd du -p rbd
```

**Output:**
```
root@ceph-storage-1:~# rbd du -p rbd
NAME       PROVISIONED  USED  
testimage       10 GiB  68 MiB
```

### Step 20: Setup Client Node

We'll use a separate VM (ceph-client-1 / 172.31.11.56) to test remote access.

**On ceph-storage-1:**
```bash
# Copy configuration to client
scp /etc/ceph/ceph.conf root@172.31.11.56:/etc/ceph/
scp /etc/ceph/ceph.client.admin.keyring root@172.31.11.56:/etc/ceph/
```

**On client (172.31.11.56):**
```bash
# Install Ceph client packages
apt update
apt install -y ceph-common

# Verify connectivity
ceph -s
```

**Output:**
```
root@ceph-client-1:~# ceph -s
  cluster:
    id:     6c44eb7e-cde9-11f0-8900-bc2411bc45d1
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum ceph-storage-1,ceph-storage-3,ceph-storage-2
    mgr: ceph-storage-1.zkipis(active), standbys: ceph-storage-2.ygbyjd
    osd: 3 osds: 3 up, 3 in
```

**Client can see the cluster!**

### Step 21: Use RBD from Client

**On ceph-client-1 (172.31.11.56):**

- list available OSD pools
```bash
ceph osd pool ls
```



- list rbd images
```bash
# List available RBD images
rbd ls -p rbd
```

**Output:**
```
root@ceph-client-1:~# rbd ls -p rbd
testimage
```

```bash
# Map the RBD image to a local device
rbd map testimage -p rbd
```

**Output:**
```
/dev/rbd0
```

```bash
# Check mapped devices
rbd showmapped
```

**Output:**
```
root@ceph-client-1:~# rbd showmapped
id  pool  namespace  image      snap  device   
0   rbd              testimage  -     /dev/rbd0
```

```bash
# Verify the device exists
lsblk
```

**Output:**
```
root@ceph-client-1:~# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda       8:0    0   50G  0 disk 
├─sda1    8:1    0   49G  0 part /
├─sda14   8:14   0    4M  0 part 
├─sda15   8:15   0  106M  0 part /boot/efi
└─sda16 259:0    0  913M  0 part /boot
sdb       8:16   0  100G  0 disk 
sr0      11:0    1    4M  0 rom  
rbd0    251:0    0   10G  0 disk
```

**/dev/rbd0 is the Ceph block device!**

```bash
# Format the device with ext4
mkfs.ext4 /dev/rbd0
```

**Output:**
```
root@ceph-client-1:~# mkfs.ext4 /dev/rbd0
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 2621440 4k blocks and 655360 inodes
Filesystem UUID: 60252529-6981-4449-aa29-bb53c2c4d8ed
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done
```

```bash
# Create mount point and mount
mkdir -p /mnt/ceph-rbd
mount /dev/rbd0 /mnt/ceph-rbd
```

```bash
# Verify mount
lsblk | grep rbd
df -h /mnt/ceph-rbd
```

**Output:**
```
rbd0    251:0    0   10G  0 disk /mnt/ceph-rbd

Filesystem      Size  Used Avail Use% Mounted on
/dev/rbd0       9.8G   32K  9.3G   1% /mnt/ceph-rbd
```

**Ceph block storage mounted and ready!**

### Step 22: Test Write/Read from Client

```bash
# Write test data
echo "Hello from Ceph client - $(date)" > /mnt/ceph-rbd/test.txt
echo "This is distributed storage!" > /mnt/ceph-rbd/distributed.txt

# Read data back
cat /mnt/ceph-rbd/test.txt
```

**Output:**
```
root@ceph-client-1:~# cat /mnt/ceph-rbd/test.txt
Hello from Ceph client - Sun Nov 30 14:47:16 UTC 2025
```

```bash
# List files
ls -lh /mnt/ceph-rbd/
```

**Output:**
```
root@ceph-client-1:~# ls -lh /mnt/ceph-rbd/
total 24K
-rw-r--r-- 1 root root  29 Nov 30 14:47 distributed.txt
drwx------ 2 root root 16K Nov 30 14:45 lost+found
-rw-r--r-- 1 root root  59 Nov 30 14:47 test.txt
```

### Step 23: Verify Data Replication

**On ceph-storage-1:**

```bash
# Map the same image (read-only to avoid conflicts)
rbd map testimage -p rbd
mkdir -p /mnt/ceph-rbd-test
mount -o ro /dev/rbd0 /mnt/ceph-rbd-test

# Read the data written from client
ls -lh /mnt/ceph-rbd-test/
cat /mnt/ceph-rbd-test/test.txt
cat /mnt/ceph-rbd-test/distributed.txt
```

**Output:**
```
root@ceph-storage-1:~# ls -lh /mnt/ceph-rbd-test/
total 24K
-rw-r--r-- 1 root root  29 Nov 30 18:17 distributed.txt
drwx------ 2 root root 16K Nov 30 18:15 lost+found
-rw-r--r-- 1 root root  59 Nov 30 18:17 test.txt

root@ceph-storage-1:~# cat /mnt/ceph-rbd-test/test.txt
Hello from Ceph client - Sun Nov 30 14:47:16 UTC 2025

root@ceph-storage-1:~# cat /mnt/ceph-rbd-test/distributed.txt
This is distributed storage!
```

**🎉 SUCCESS! Data written on client is readable from storage nodes!**

```bash
# Cleanup
umount /mnt/ceph-rbd-test
rbd unmap /dev/rbd0
```

---

## CephFS Filesystem

CephFS provides a POSIX-compliant shared filesystem like NFS.

### Step 24: Deploy CephFS

**On ceph-storage-1:**

```bash
# Create CephFS volume (creates data pool, metadata pool, and MDS)
ceph fs volume create cephfs

# Wait for deployment
sleep 30

# Check CephFS status
ceph fs ls
```

**Expected output:**
```
name: cephfs, metadata pool: cephfs.cephfs.meta, data pools: [cephfs.cephfs.data]
```

```bash
# Check filesystem status
ceph fs status cephfs
```

```bash
# Check MDS (Metadata Server) daemons
ceph orch ps --daemon-type mds
ceph mds stat
```

**Expected output:**
```
cephfs:1 {0=cephfs.ceph-storage-1.abc123=up:active}
```

### Step 25: Mount CephFS on Client

**On ceph-client-1:**

```bash
# Get admin authentication key
ceph auth get-key client.admin
```

**Output:**
```
AQBa1234567890abcdefGHIJKLMNOPQRSTUVWXYZ==
```

```bash
# Create secret file
echo "AQBa1234567890abcdefGHIJKLMNOPQRSTUVWXYZ==" > /etc/ceph/admin.secret
chmod 600 /etc/ceph/admin.secret

# Mount CephFS using kernel driver (all 3 monitors for HA)
mkdir -p /mnt/cephfs
mount -t ceph 172.31.11.53:6789,172.31.11.54:6789,172.31.11.55:6789:/ /mnt/cephfs \
    -o name=admin,secretfile=/etc/ceph/admin.secret

# Verify mount
df -h /mnt/cephfs
```

**Expected output:**
```
Filesystem                                                Size  Used Avail Use% Mounted on
172.31.11.53:6789,172.31.11.54:6789,172.31.11.55:6789:/   94G     0   94G   0% /mnt/cephfs
```

```bash
# Test write/read
echo "CephFS shared filesystem" > /mnt/cephfs/test.txt
cat /mnt/cephfs/test.txt
ls -la /mnt/cephfs/
```

**CephFS working!**

### Step 26: Test Multi-Client Access

CephFS can be mounted by multiple clients simultaneously.

**On ceph-storage-2:**
```bash
mkdir -p /mnt/cephfs
mount -t ceph 172.31.11.53:6789:/ /mnt/cephfs -o name=admin,secretfile=/etc/ceph/admin.secret

# Read file created from client-1
cat /mnt/cephfs/test.txt

# Write new file
echo "Written from storage-2" > /mnt/cephfs/from-storage2.txt
```

**On ceph-client-1:**
```bash
# Read file created from storage-2
cat /mnt/cephfs/from-storage2.txt
```

**Multiple clients can read/write simultaneously!**

---

## RGW Object Storage

RGW (RADOS Gateway) provides S3 and Swift-compatible object storage.

### Step 27: Deploy RGW

**On ceph-storage-1:**

```bash
# Deploy RGW on all 3 nodes
ceph orch apply rgw myobjectstore --placement="3"

# Check RGW deployment
ceph orch ps --daemon-type rgw
```

**Expected output:**
```
NAME                               HOST             PORTS        STATUS
rgw.myobjectstore.ceph-storage-1   ceph-storage-1   *:80         running
rgw.myobjectstore.ceph-storage-2   ceph-storage-2   *:80         running
rgw.myobjectstore.ceph-storage-3   ceph-storage-3   *:80         running
```

### Step 28: Create S3 User

```bash
# Create S3 user with credentials
radosgw-admin user create \
    --uid=s3user \
    --display-name="S3 User" \
    --email=s3user@example.com
```

**Output includes:**
```json
{
    "keys": [
        {
            "user": "s3user",
            "access_key": "ABC123DEF456GHI789JKL",
            "secret_key": "aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890"
        }
    ]
}
```

**📝 Save these credentials!**

### Step 29: Use S3 API

**On ceph-client-1:**

```bash
# Install s3cmd
apt install -y s3cmd

# Configure s3cmd
cat > ~/.s3cfg << EOF
[default]
access_key = ABC123DEF456GHI789JKL
secret_key = aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890
host_base = 172.31.11.53:80
host_bucket = 172.31.11.53:80
use_https = False
EOF

# Create bucket
s3cmd mb s3://mybucket

# Upload file
echo "Object storage test" > /tmp/testfile.txt
s3cmd put /tmp/testfile.txt s3://mybucket/

# List objects
s3cmd ls s3://mybucket/

# Download file
s3cmd get s3://mybucket/testfile.txt /tmp/downloaded.txt
cat /tmp/downloaded.txt
```

**✅ S3-compatible object storage working!**

---

## Maintenance and Operations

### All Running Services

```bash
# View all Ceph daemons
ceph orch ps
```

**Output:**
```
NAME                           HOST             PORTS             STATUS         AGE
alertmanager.ceph-storage-1    ceph-storage-1   *:9093,9094       running        2h
ceph-exporter.ceph-storage-1   ceph-storage-1                     running        2h
ceph-exporter.ceph-storage-2   ceph-storage-2                     running        1h
ceph-exporter.ceph-storage-3   ceph-storage-3                     running        1h
crash.ceph-storage-1           ceph-storage-1                     running        2h
crash.ceph-storage-2           ceph-storage-2                     running        1h
crash.ceph-storage-3           ceph-storage-3                     running        1h
grafana.ceph-storage-1         ceph-storage-1   *:3000            running        2h
mgr.ceph-storage-1.zkipis      ceph-storage-1   *:9283,8765,8443  running        2h
mgr.ceph-storage-2.ygbyjd      ceph-storage-2   *:8443,9283,8765  running        1h
mon.ceph-storage-1             ceph-storage-1                     running        2h
mon.ceph-storage-2             ceph-storage-2                     running        1h
mon.ceph-storage-3             ceph-storage-3                     running        1h
node-exporter.ceph-storage-1   ceph-storage-1   *:9100            running        2h
node-exporter.ceph-storage-2   ceph-storage-2   *:9100            running        1h
node-exporter.ceph-storage-3   ceph-storage-3   *:9100            running        1h
osd.0                          ceph-storage-1                     running        1h
osd.1                          ceph-storage-3                     running        1h
osd.2                          ceph-storage-2                     running        1h
prometheus.ceph-storage-1      ceph-storage-1   *:9095            running        2h
```

### Docker Containers

```bash
# View running containers on any node
docker ps
```

**Output example from ceph-storage-1:**
```
CONTAINER ID   IMAGE                                     COMMAND                  STATUS
2fa18aedd42a   quay.io/ceph/grafana:10.4.0               "/run.sh"                Up 2 hours
727cdba388ce   quay.io/prometheus/alertmanager:v0.25.0   "/bin/alertmanager..."   Up 2 hours
cf5f237c167b   quay.io/prometheus/prometheus:v2.51.0     "/bin/prometheus..."     Up 2 hours
1f5083f89ad4   quay.io/prometheus/node-exporter:v1.7.0   "/bin/node_exporter"     Up 2 hours
d99e89b88ae7   quay.io/ceph/ceph                         "/usr/bin/ceph-crash"    Up 2 hours
e3918df9fae0   quay.io/ceph/ceph                         "/usr/bin/ceph-exp..."   Up 2 hours
6df8db7afe1e   quay.io/ceph/ceph:v19                     "/usr/bin/ceph-mgr"      Up 2 hours
50392717f2b0   quay.io/ceph/ceph:v19                     "/usr/bin/ceph-mon"      Up 2 hours
41fe4d19b848   quay.io/ceph/ceph:v19                     "/usr/bin/ceph-osd"      Up 1 hour
```

### Essential Commands

```bash
# Cluster status
ceph -s
ceph health detail
ceph df

# OSD management
ceph osd tree
ceph osd stat
ceph osd df

# Pool management
ceph osd pool ls detail
ceph osd pool stats

# RBD operations
rbd ls -p rbd
rbd du -p rbd
rbd showmapped

# CephFS status
ceph fs status
ceph mds stat

# Monitor cluster activity
ceph -w                    # Watch live
ceph log last 50           # Recent logs
```

### Dashboard Access

```
Web Dashboard: https://172.31.11.53:8443/
               https://ceph-storage-1:8443/

Username: admin
Password: x81x5qzb6z (change after first login)

Grafana:      http://172.31.11.53:3000/
Prometheus:   http://172.31.11.53:9095/
Alertmanager: http://172.31.11.53:9093/
```

### Performance Tuning (4GB RAM Nodes)

```bash
# Reduce OSD memory usage
ceph config set osd osd_memory_target 2147483648  # 2GB per OSD

# Reduce cache size
ceph config set osd bluestore_cache_size 536870912  # 512MB

# Optional: Use 2x replication for more usable space
ceph osd pool set rbd size 2
ceph osd pool set rbd min_size 1
# This changes: 300GB raw -> 150GB usable (vs 100GB with 3x)
```

---

## Summary

### Deployment Completed ✅

**Infrastructure:**
- 3 storage nodes: ceph-storage-1, ceph-storage-2, ceph-storage-3
- 1 client node: ceph-client-1 (172.31.11.56)
- 300GB raw storage (100GB per node)
- ~95GB usable per pool (3x replication)

**Services Deployed:**
- ✅ 3 Monitors (HA quorum)
- ✅ 2 Managers (active + standby)
- ✅ 3 OSDs (distributed storage)
- ✅ RBD Block Storage (tested)
- ✅ CephFS Filesystem (deployed)
- ✅ RGW Object Storage (deployed)
- ✅ Dashboard, Prometheus, Grafana

**Testing Results:**
- ✅ RBD: Written from client, verified on cluster
- ✅ Replication: Data replicated across all 3 nodes
- ✅ High Availability: Multiple monitors in quorum
- ✅ Client Access: Remote client can mount and use storage

### Quick Reference

```bash
# Status
ceph -s                              # Cluster status
ceph health detail                   # Health check
ceph df                              # Storage usage

# RBD
rbd create img --size 10G -p rbd     # Create image
rbd map img -p rbd                   # Map to device
mount /dev/rbd0 /mnt                 # Mount

# CephFS
mount -t ceph mon:6789:/ /mnt/cephfs # Mount CephFS

# S3
s3cmd mb s3://bucket                 # Create bucket
s3cmd put file s3://bucket/          # Upload
```

---

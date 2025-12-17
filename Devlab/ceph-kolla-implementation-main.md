
# Ceph Cluster Deployment:

## Ceph Architecture ([ARCHITECTURE](https://docs.ceph.com/en/reef/architecture/))
Ceph uniquely delivers **object**, **block**, **and file storage** in one unified system. Ceph is highly reliable, easy to manage, and free. Ceph delivers extraordinary scalability–thousands of clients accessing petabytes to exabytes of data. A [Ceph Node](https://docs.ceph.com/en/reef/glossary/#term-Ceph-Node) leverages commodity hardware and intelligent daemons, and a [Ceph Storage](https://docs.ceph.com/en/reef/glossary/#term-Ceph-Storage-Cluster) Cluster accommodates large numbers of nodes, which communicate with each other to replicate and redistribute data dynamically.


### Monitors (MON)
A daemon that maintains a map of the state of the cluster. This “cluster state” includes the monitor map, the manager map, the OSD map, and the CRUSH map. A Ceph cluster must contain a minimum of three running monitors in order to be both redundant and highly-available. Ceph monitors and the nodes on which they run are often referred to as “mon”s. [MONITOR CONFIG REFRENCE](https://docs.ceph.com/en/reef/rados/configuration/mon-config-ref/#monitor-config-reference) </br>
the number of Monitoring Nodes should be an oddnumber because it will be possible to always elect the true data when a client triesto mount a block device. when client wants to mount a block device, the first thing, it checks with `mons` and take a copy of cluster map, then it uses that map for read/write based on cluster map and applies the crash algorithm to pinpoint which object storage is holding the data.


### Object Storage Daemon (OSD) ([OSD-Service](https://docs.ceph.com/en/latest/cephadm/services/osd/))
if Monitors are the brain, the OSDs are the muscles. they store data, replicate, rebalance and etc. each osd typically manages a single physical disk and exposes a client API so clients can talk to them directly. the more OSD means the more parallel reads and writes. that means better performance, no bottle-neck and a scalable system.


### Placement Groups (PG)
Placement groups (PGs) are subsets of each logical Ceph pool. Placement groups perform the function of placing objects (as a group) into OSDs. Ceph manages data internally at placement-group granularity: this scales better than would managing individual RADOS objects. A cluster that has a larger number of placement groups (for example, 150 per OSD) is better balanced than an otherwise identical cluster with a smaller number of placement groups.
- [Monitoring OSDs and PGS](https://docs.ceph.com/en/reef/rados/operations/monitoring-osd-pg/#monitoring-osds-and-pgs)
- [PG (Placement Group) Notes](https://docs.ceph.com/en/latest/dev/placement-group/#pg-placement-group-notes)
- [Placement Groups](https://docs.ceph.com/en/latest/rados/operations/placement-groups/)


### Managers (mgr)
The Ceph manager daemon (ceph-mgr) is a daemon that runs alongside monitor daemons to provide monitoring and interfacing to external monitoring and management systems. it gives you a windows into the cluster health and performance. it runs the web dashboard, collect metrics, and basically act as a watch tower. mgr also hosts all plugins such as dashboard, grafana, prometheus adn etc 


## Setting Up 3 Nodes Cluster
in these steps we are going to setup 3 node cluster for ceph.
### requirements:
- 3x Ubuntu Server with 4 Core and 8GB of RAM with 50GB Disk for OS and 100GB Unmounted Disk (the more disk means more parallel read/write and Distribution of Data)
- docker install on all threse Nodes (becuase cephadm will use docker to deploy services containers) [Docker Installation on Ubuntu](https://docs.docker.com/engine/install/ubuntu/) 


### Configurations
0. update your OS packages
- `sudo apt update`

#### 1. Preconfigurations on Each OS
1. turn off swap on all nodes (because ceph is designed to manage memory and to ensure predictable behavior. we don't want it to start swaping)
- `swapoff -a`
- `vim /etc/fstab`; `comment out mounted related to swap` for permanent

2. check out free memory
- `free -m`

3. install pacakges 
- `apt install cephadm`


#### 2. bootstraping cluster ([CEPH BOOTSTRAP INFORMATION](https://docs.ceph.com/en/latest/cephadm/install/#further-information-about-cephadm-bootstrap))
1. if you have your local registry also include `--image` in your bootstrap but if not just remove it and its value. then by `--mon-ip` we define which server should be the monitor service. </br>
in this case because we only have  
- `cephadm --image *<hostname>*:5000/ceph/ceph bootstrap --mon-ip *<mon-ip>*` </br>
example:
- `cephadm --image reg.abrvand.ir/quay.io/ceph/ceph:v19.2.3  bootstrap --mon-ip 172.31.11.152 --initial-dashboard-user admin --initial-dashboard-password admin123`

check running dockers
- `docker ps`


#### 3. Copy Ceph SSH keys to other Cluster Nodes
0. change the ssh-cloud config PasswordAuthentication to 'yes':
- `sudo grep -q "PasswordAuthentication" /etc/ssh/sshd_config.d/60-cloudimg-settings.conf && sudo sed -i -r 's/^[[:space:]]*(#)?[[:space:]]*PasswordAuthentication[[:space:]]+(yes|no)/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf || sudo echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config.d/60-cloudimg-settings.conf; sudo systemctl restart ssh`

or 
- `sudo vim /etc/ssh/sshd_config.d/60-cloudimg-settings.conf`
- `sudo systemctl restart ssh`

1. copy the ssh-key to ceph
- `ssh-copy-id -f -i /etc/ceph/ceph.pub ubuntu@172.31.11.153`
- `ssh-copy-id -f -i /etc/ceph/ceph.pub ubuntu@172.31.11.154`  

2. Authorize ssh public keys for root (all nodes). create a .ssh directory in root of each node as follow:
- `sudo mkdir -p /root/.ssh; sudo chmod 700 /root/.ssh; sudo chmod 600 /root/.ssh/authorized_keys; sudo chown -R root:root /root/.ssh`

- `grep ' ceph-' /home/ubuntu/.ssh/authorized_keys | sudo tee -a /root/.ssh/authorized_keys` => it is going to copy ubuntu user newly added authorized key which is for ceph to root's authorized keys.


#### 4. Enable CEPH CLI 
The `cephadm shell` command launches a bash shell in a container with all of the Ceph packages installed. By default, if configuration and keyring files are found in /etc/ceph on the host, they are passed into the container environment so that the shell is fully functional. 
- create ceph package container:
```sh
cephadm shell
```

- verify it (this command is being executed inside ceph shell container):
```sh
ceph -s
ceph orch ps 
```


### Pre-Registry Configuration Checks
1. first we need to check our default image repository:
- `ceph config get mgr mgr/cephadm/container_image_base` => it shows the base registry
<!-- - `ceph config get mgr mgr/cephadm/container_image_tag` => it shows the tag of images --> #wrong syntax - NEEDS REVISION
- `ceph config get mgr mgr/cephadm/container_image_node_exporter`  #it might not be beginning of deployment so it shout be `set`
- `ceph config get mgr mgr/cephadm/container_image_prometheus` #it might not be beginning of deployment so it shout be `set`
- `ceph config get mgr mgr/cephadm/container_grafana` #it might not be beginning of deployment so it shout be `set`
- `ceph config get mgr mgr/cephadm/container_image_alertmanager` #it might not be beginning of deployment so it shout be `set`

2. check your current ceph version (**it will be used for registry taging**)
- `ceph -v`


### Setting New Registry
In this step, registry and image directory of each service is explicitly define with **its version** keep in mind that `:latest` versioning is highly discouraged. for lack of inconsistency in versioning.

1. change the registry by:
- `ceph config set mgr mgr/cephadm/container_image_base <reg.abrvand.ir/quay.io>`
- `ceph config set mgr mgr/cephadm/container_image_prometheus reg.abrvand.ir/quay.io/prometheus/prometheus:v2.51.0`
- `ceph config set mgr mgr/cephadm/container_image_alertmanager reg.abrvand.ir/quay.io/prometheus/alertmanager:v0.25.0`
- `ceph config set mgr mgr/cephadm/container_image_grafana reg.abrvand.ir/quay.io/ceph/grafana:10.4.0`
- `ceph config set mgr mgr/cephadm/container_image_node_exporter reg.abrvand.ir/quay.io/prometheus/node-exporter:v1.7.0`

verify it: 
- `ceph config get mgr mgr/cephadm/container_image_base`
- `ceph config dump | grep container_image`


### Redeploy daemons to apply changes

1. redeploy services (this process can take time)
`ceph orch redeploy prometheus`
`ceph orch redeploy alertmanager`
`ceph orch redeploy grafana`
`ceph orch redeploy node-exporter`

verify it on docker engine: </br>
- `docker ps -a`


### Add Hosts to Cluster ([ADDING HOSTS](https://docs.ceph.com/en/latest/cephadm/host-management/#adding-hosts))
To add each new host to the cluster, we need to perform `ceph orch` command inside the **ceph shell** created by `cephadm shell`:
- list all currently added host to ceph cluster
```sh
ceph orch host ls
```

**note:**
> By default, a `ceph.conf` file and a copy of the `client.admin` keyring are maintained in `/etc/ceph` on all hosts that have the `_admin` label. This label is initially applied only to the bootstrap host. We recommend that one or more other hosts be given the `_admin` label so that the Ceph CLI (for example, via `cephadm shell`) is easily accessible on multiple hosts.
- add hosts to cluster **(with `_admin` labels we can have multiple admin cluster and managable in failure**) it is also recommended to set the host name as the real hostname of that host.
```sh
ceph orch host add ceph-v-srv2 172.31.11.153 --labels _admin
ceph orch host add ceph-v-srv3 172.31.11.154 --labels _admin
```


### add OSD devices to cluster
1. List devices on a host
- `ceph orch device ls`

2. Create OSD daemon(s) on all available devices which are unmounted and doesn't have partitions and file system (clean blank block device)
- `ceph orch apply osd --all_available_devices`

verify that OSD deamons are running on each block device
- `ceph -s` => there should be 3 OSD (or more based on your available disk).
- `ceph osd tree` => it will list the OSDs and their stats


### Integrating With GUI
to use ceph core capabilities like volume, management, thin provisioning, snapshots, cloning, copy on write and etc, we can also use Web GUI beside using CLI or directly manaing with Openstack via ceph api API. in this step we are using Ceph GUI:
1. connect to Ceph web GUI via your browser:
- `https://172.31.11.152:8443` +> login with the password that you have entered in boostrap. 


#### If User/Password is forgotten use the below step to set new password:
The guide for [Changing the Ceph Dashboard Password using the command line interface](https://www.ibm.com/docs/en/storage-ceph/7.1.0?topic=ia-changing-ceph-dashboard-password-using-command-line-interface)  
1. `cephadm shell`
2. `vi dashboard_password.yml` => put the password in the `yaml` file
3. `ceph dashboard ac-user-set-password DASHBOARD_USERNAME -i dashboard_password.yml`



### Ceph Dashboard Concepts ([Ceph Dashboard](https://docs.ceph.com/en/latest/mgr/dashboard/)):
The Ceph Dashboard is a web-based Ceph management-and-monitoring tool that can be used to inspect and administer resources in the cluster. It is implemented as a Ceph Manager Daemon module.

if you are running a multi node cluster and want to where the dashboard is located:
- `ceph mgr services | jq .dashboard`



...

# Ceph Cluster Openstack Implementation
This Document is followed by [This Tutorial](https://www.youtube.com/watch?v=VF01hPMtz_Y&list=PLUF494I4KUvq1pbYBDoQQomRgoNRgvdzC&index=1)


### What is [Ceph](https://docs.ceph.com/en/reef/)?
Ceph is an open-source, software-defined, distributed storage system that unifies object, block, and file storage into a single, highly scalable, and reliable platform for modern data centers and clouds, allowing you to store massive amounts of data on commodity hardware with self-healing and self-managing capabilities.


## How Does Ceph Work in Openstack 
You can attach Ceph Block Device images to OpenStack instances through `libvirt`, which configures the `QEMU` interface to `librbd`. Ceph stripes block volumes across multiple OSDs within the cluster, which means that **large volumes can realize better performance than local drives on a standalone server**!

![openstack-ceph-diagram](https://docs.ceph.com/en/latest/_images/ditaa-79a3df369d39dfa94fcac8161406c50b54bf2a7e.png)

Note:
> To use Ceph Block Devices with OpenStack, you must have access to a running Ceph Storage Cluster


## Ceph Configuration for Openstack

### Pools Creation
Each Openstack service can work with its specific pool in ceph and it is best practice to created segmented pools for each of them.

- **Images**: OpenStack Glance manages images for VMs. Images are immutable. OpenStack treats images as binary blobs and downloads them accordingly.
- **Volumes**: Volumes are block devices. OpenStack uses volumes to boot VMs, or to attach volumes to running VMs. OpenStack manages volumes using Cinder services.
- **Guest Disks**: Guest disks are guest operating system disks. By default, when you boot a virtual machine, its disk appears as a file on the file system of the hypervisor

You can use OpenStack Glance to store images as Ceph Block Devices, and you can use Cinder to boot a VM using a copy-on-write clone of an image.


Important:
>  Using `QCOW2` for hosting a virtual machine disk is NOT recommended. If you want to boot virtual machines in Ceph (ephemeral backend or boot from volume), please use the `raw` image format within Glance


### Creating Pool
it recommends creating a pool for Cinder and a pool for Glance. Ensure your Ceph cluster is running, then create the pools. **the following names are what openstack expects by default** </br>
1. on ceph machine create pool for each service:
```sh
ceph osd pool create volumes
ceph osd pool create images
ceph osd pool create backups
ceph osd pool create vms

#verify them via
ceph osd pool ls
```

2. it is recommended to identify to ceph, what kind of data is each pool going to use.
```sh
ceph osd pool application enable volumes rbd
ceph osd pool application enable images rbd
ceph osd pool application enable vms rbd
ceph osd pool application enable backups rbd

```


3. Newly created pools must be initialized prior to use rbd
```sh
rbd pool init volumes
rbd pool init images
rbd pool init backups
rbd pool init vms
```

```
rbd device list #list mapped devices
rbd pool stats #display pool statistics
rbd status
```


### Setup Ceph Client Authentication
for connecting openstack to ceph we need to use "**CephX Authentication and Protocol**". The CephX protocol is enabled by default. create a new user for Nova/Cinder and Glance. Execute the following:

- setup a user for glance service. we grant access to monitors with rbd porfile that provides minimum necessary permissions for an RBD client and also grant permissions to storage demons OSDs. with profile rbd we grant read/write on images pool for this user  </br>
`ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images' -o ceph.client.glance.keyring` 

output:
```
[client.glance]
        key = AQAcVzVpYTAJNRAA6slBJKQsmqBo0ONib1/InA==
```


- create and assign permissions to relative pools and profile for cinder service </br>
`ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms' -o ceph.client.cinder.keyring`

`ceph auth get client.cinder-backup`: </br>

output:
```
[client.cinder-backup]
        key = AQCGVzVp2gmEGBAAI6n+oE9YGo+CZVlDiA9/8A==
        caps mgr = "profile rbd pool=backups"
        caps mon = "profile rbd"
        caps osd = "profile rbd pool=backups"
```


- create and assign permissions to relative pools and profile for cinder backups </br>
`ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups' -o ceph.client.cinder-backup.keyring`

output:
```
[client.cinder-backup]
        key = AQCGVzVp2gmEGBAAI6n+oE9YGo+CZVlDiA9/8A==
```


## change configuration on kolla-ansible `globals.yml` 

1. change the configuration of `globals.yml` file in `/etc/kolla/` or create a `ceph-enabled.yml` file in `/etc/kolla/globals.d/` and change these configuration:
- `vim /etc/kolla/globals.yml`

```yaml
---
workaround_ansible_issue_8743: true
kolla_base_distro: "ubuntu"
kolla_internal_vip_address: "172.31.11.159"
network_interface: "eth0"
neutron_external_interface: "enp6s19"
enable_cinder: true
cinder_backend_ceph: true
enable_cinder_backup: true
cinder_backup_driver: "ceph"
glance_backend_ceph: true
nova_backend_ceph: true
ceph_cinder_backup_user: "cinder-backup"
ceph_glance_user: "glance"
ceph_cinder_user: "cinder"
ceph_nova_user: "{{ ceph_cinder_user }}"
```


### Add the `ceph.conf` and keyrings for `client.cinder`, `client.glance`, and `client.cinder-backup` to the appropriate nodes and change their ownership

openstack service with kolla will be running in docker containers but they will read the configuration from the host filesystem which in our case is `/etc/kolla/config/cinder/cinder-backup`

1. create the directories for each file
- ` mkdir -p /etc/kolla/config/glance `
- ` mkdir -p /etc/kolla/config/nova `
- ` mkdir -p /etc/kolla/config/cinder/cinder-backup/ `
- ` mkdir -p /etc/kolla/config/glance/cinder-volume/ `


2. copy and send the `ceph.conf` from ceph cluster into openstack's services directory:
- `scp /etc/ceph/ceph.conf <USERNAME>@<SERVICE_SERVER_IP>:/etc/kolla/config/glance/ceph.conf`
- `cp /etc/kolla/config/glance/ceph.conf /etc/kolla/config/cinder/cinder-backup`
- `cp /etc/kolla/config/glance/ceph.conf /etc/kolla/config/cinder/cinder-backup/`
- `cp /etc/kolla/config/glance/ceph.conf /etc/kolla/config/cinder/cinder-volume/`
- `cp /etc/kolla/config/glance/ceph.conf /etc/kolla/config/nova/`


3. add credentials for each service
- `ceph auth get client.glance -o ceph.client.glance.keyring && scp ceph.client.glance.keyring <USERNAME>@<SERVICE_SERVER_IP>:/etc/kolla/config/glance/`
- `ceph auth get client.cinder -o ceph.client.glance.keyring && scp ceph.client.cinder.keyring <USERNAME>@<SERVICE_SERVER_IP>:/etc/kolla/config/cinder/cinder-volume`
- `ceph auth get client.cinder-backup -o ceph.client.cinder-backup.keyring && scp ceph.client.cinder-backup.keyring <USERNAME>@<SERVICE_SERVER_IP>:/etc/kolla/config/cinder/cinder-backup`
- `ceph auth get client.cinder -o ceph.client.cinder.keyring && scp ceph.client.cinder.keyring <USERNAME>@<SERVICE_SERVER_IP>:/etc/kolla/config/nova/`


this should be the final result:
```
config/
├── cinder
│   ├── cinder-backup
│   │   ├── ceph.client.cinder.keyring (it has backup keyring)
│   │   └── ceph.conf
│   └── cinder-volume
│       ├── ceph.client.cinder.keyring
│       └── ceph.conf
├── glance
│   ├── ceph.client.glance.keyring
│   ├── ceph.conf
│   └── glance-api.conf
└── nova
    ├── ceph.client.cinder.keyring
    └── ceph.conf
```


4. apply changes on **an existing kolla cluster** 
- `kolla-ansible reconfigure -i all-in-one`

if you are running new cluster, run:
- `kolla ansible deploy -i all-in-one`


5. verify that services are running:
- `openstack volume service list`

go into nova container and verify the configuration:
- `docker exec -it nova_compute /bin/bash`
        - `ls -l /etc/ceph` => lists the configurations in it


### Test Ceph Backend on Openstack
verify the ceph implementation by using its services in following scenario:

1. download a light weight image.
- `wget https://download.cirros-cloud.net/0.6.3/cirros-0.6.3-x86_64-disk.img`

2. check its format (it will be in `qemu`)
- `file cirros-0.6.3-x86_64-disk.img`

3. we need conver that image into `raw` format
- `qemu-img convert -f qcow2 -O raw cirros-0.6.3-x86_64-disk.img cirros.raw `

4. upload the image to glance
- `openstack image create cirros --file cirros.raw --disk-format raw --container-format bare --public`

5. confirm the image upload:
- `openstack image list`

6. **on ceph cluster**: check if the image pool in image pool has now a new RBD image. (its name should be match with glance image ID)
- `rbd ls images`
- `rbd snap ls images/<ID>` (to check if it is protected)

7. **on openstack cluster** create a new cinder volume with the image:
- `openstack volume create --image cirros --size 10 boot-volume` </br>
verify it via:
- `openstack volume ls`

8. **on ceph cluster**: verify that new RBD is also created parallel to the cinder
- `rbd ls volumes` => its ID should be matched
- `rbd info volumes/volume-<ID>` => it should have a parent image snapshot (`@snap`)
- `rbd children images/<ID@snap>` => it will confirm that it is a **copy on write clone** which it means that it cause optimization on creating OS machines from it.


### Boot new machine with created volume as its root disk
1. spin up new machine with volume
- `openstack server --flavor m1.tiny --network <network-name> --volume <volume-name> <vm-name>`

2. check what images it is using
- `openstack server list`

3. **on ceph cluster**: check if the watcher is enabled on volume
- `rbd ls volumes`
- `rbd status volumes/volume-<ID>`


#### What is the Watcher?
VM boots and qemu opens its RBD backed disk. qemu acquires an exclusive lock on the image and ensures that no two clients write at once, at the same time, the watcher ensures that Qemu is notified when the image is resized, snapshots are created/removed, image is flattened or clone and etc.


boot the another VM but this time with image on ephemeral disk and check the machines Image status
- `openstack server create --flavor m1.tiny --network <network-name> --image cirros <vm-name2>`
- `openstack server list`

- `rbd ls vms` => **on ceph cluster** vms check that new disk is created
- `rbd info vms/<ID_Disk>`
- `rbd children images/<ID@snap>` => now it should have two children which one is ephemeral and other is from volume



### Backup From boot volume
1. initate a backup process for boot volume 
`openstack volume backup create --name <boot-volume-name> <volume-name> --force` => force flag is used because it is in use

2. list available backups
- `openstack volume backup list` (if the incremental flag is `false` it means it has the full copy)

3. **on ceph cluster**, check the backup rbd:
- `rbd ls backups`
- `rbd info backups/volume-<id>`
- `rbd snap ls bakups/volume-<id>` => it  should show that cinder backup has also created a snapshot of this new backup image.

we can change the backup to incremental backup via:
- `openstack volume backup create --name <boot-volume-name> <volume-name> --force --incremental`
- `openstack volume backup list`
- `rbd snap ls backups/volume-<ID>` => it will show that new snapshot is created (the new snapshot has a pointer to previous snapshot and openstack uses diff to find the changes)



# Ceph RBD and Openstack Implementation
This Document is followed by 

You can attach Ceph Block Device images to OpenStack instances through `libvirt`, which configures the `QEMU` interface to `librbd`. Ceph stripes block volumes across multiple OSDs within the cluster, which means that **large volumes can realize better performance than local drives on a standalone server**!

![openstack-ceph-diagram](https://docs.ceph.com/en/latest/_images/ditaa-79a3df369d39dfa94fcac8161406c50b54bf2a7e.png)

Note:
> To use Ceph Block Devices with OpenStack, you must have access to a running Ceph Storage Cluster


#### Three parts of OpenStack integrate with Ceph’s block devices:
- **Images**: OpenStack Glance manages images for VMs. Images are immutable. OpenStack treats images as binary blobs and downloads them accordingly.
- **Volumes**: Volumes are block devices. OpenStack uses volumes to boot VMs, or to attach volumes to running VMs. OpenStack manages volumes using Cinder services.
- **Guest Disks**: Guest disks are guest operating system disks. By default, when you boot a virtual machine, its disk appears as a file on the file system of the hypervisor

You can use OpenStack Glance to store images as Ceph Block Devices, and you can use Cinder to boot a VM using a copy-on-write clone of an image.


Important:
>  Using `QCOW2` for hosting a virtual machine disk is NOT recommended. If you want to boot virtual machines in Ceph (ephemeral backend or boot from volume), please use the `raw` image format within Glance


## Creating Pool
it recommends creating a pool for Cinder and a pool for Glance. Ensure your Ceph cluster is running, then create the pools. </br>
1. on ceph machine create pool for each service:
```sh
ceph osd pool create volumes
ceph osd pool create images
ceph osd pool create backups
ceph osd pool create vms

#verify them via
ceph osd pool ls
```

2. Newly created pools must be initialized prior to use
```sh
rbd pool init volumes
rbd pool init images
rbd pool init backups
rbd pool init vms


rbd device list #list mapped devices
rbd pool stats #display pool statistics
rbd status
```



## Openstack-Ceph Configure on Clients (The Openstack Cluster Nodes)
The nodes running `glance-api`, `cinder-volume`, `nova-compute` and `cinder-backup` act as Ceph clients. Each requires the `ceph.conf` file
### Install Ceph client packages
- On the `glance-api` node, you will need the Python bindings for `librbd`:
``` sh
sudo apt install python3-rbd
```

- On the `nova-compute`, `cinder-backup` and on the `cinder-volume` node, use both the Python bindings and the client command line tools
```sh
sudo apt-get install ceph-common
```



## Setup Ceph Client Authentication
for connecting openstack to ceph we need to use "**CephX Authentication and Protocol**". The CephX protocol is enabled by default. create a new user for Nova/Cinder and Glance. Execute the following:

- create and assign permissions to relative pools and profile for glance service. </br>
`ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'` 
```
[client.glance]
        key = AQAcVzVpYTAJNRAA6slBJKQsmqBo0ONib1/InA==
```


- create and assign permissions to relative pools and profile for cinder service </br>
`ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'`
```
file rbd pool=vms'
[client.cinder]
        key = AQAmVzVpa6S/KRAA2rvEGcUJf/yrWfs5IptPOg==
```


- create and assign permissions to relative pools and profile for cinder backups </br>
`ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'`
```
[client.cinder-backup]
        key = AQCGVzVp2gmEGBAAI6n+oE9YGo+CZVlDiA9/8A==
```


### Add the keyrings for `client.cinder`, `client.glance`, and `client.cinder-backup` to the appropriate nodes and change their ownership
`ceph auth get-or-create client.glance | ssh {your-glance-api-server} sudo tee /etc/ceph/ceph.client.glance.keyring`

- retrieve, send, and configure ownership of keyrings for glance.
`ceph auth get-or-create client.glance ceph ubuntu@172.31.11.153 sudo tee /ceph.client.glance.keyring`
`ssh ubuntu@172.31.11.153 sudo chown glance:glance /ceph.client.glance.keyring`

- retrieve, send, and configure ownership of keyrings for cinder.
`ceph auth get-or-create client.cinder ceph ubuntu@172.31.11.153 sudo tee /ceph.client.cinder.keyring`
`ssh ubuntu@172.31.11.153 sudo chown cinder:cinder /ceph.client.cinder.keyring`

- retrieve, send, and configure ownership of keyrings for cinder-backup.
`ceph auth get-or-create client.cinder-backup ceph ubuntu@172.31.11.153 sudo tee /ceph.client.cinder.keyring`
`ssh ubuntu@172.31.11.153 sudo chown cinder:cinder /ceph.client.cinder-backup.keyring`

- Nodes Running `nova-compute` need the keyring file for the `nova-compute` process: </br>
`ceph auth get-or-create client.cinder | ssh {your-nova-compute-server} sudo tee /etc/ceph/ceph.client.cinder.keyring`


- They also need to store the secret key of the `client.cinder` user in `libvirt`. The `libvirt` process needs it to access the cluster while attaching a block device from Cinder. </br>

`ceph auth get-key client.cinder | ssh {your-compute-node} tee client.cinder.key`

- Then, on the compute nodes, add the secret key to `libvirt` and remove the temporary copy of the key:

```sh
uuidgen
# 457eb676-33da-42ec-9a8c-9293d545c337
```

``` sh
cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>457eb676-33da-42ec-9a8c-9293d545c337</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF
sudo virsh secret-define --file secret.xml
Secret 457eb676-33da-42ec-9a8c-9293d545c337 created
sudo virsh secret-set-value --secret 457eb676-33da-42ec-9a8c-9293d545c337 --base64 $(cat client.cinder.key) && rm client.cinder.key secret.xml
```

Save the uuid of the secret for configuring `nova-compute` later.

- Note:
> You don’t necessarily need the UUID on all the compute nodes. However from a platform consistency perspective, it’s better to keep the same UUID




``` ini
[global]
fsid = 756bc1c1-d044-11f0-882f-bc2411603ea7
keyring = /etc/ceph/ceph.client.glance.keyring
mon_initial_members = mohammadreza-ceph-srv1, mohammadreza-ceph-srv2, mohammadreza-ceph-srv3
mon_host = 172.31.11.152, 172.31.11.153, 172.31.11.154
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
```
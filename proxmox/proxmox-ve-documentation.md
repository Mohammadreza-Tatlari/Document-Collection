### Proxmox VE version-8 Debian(wormbook) 12 Documentation
• random note:
> You might use Proxmox for your underlying virtualization and OpenStack to manage the cloud layer on top. Understanding KVM, which both platforms utilize, is a very useful skill. 

### Installation:
the installation is almost similar to installing a linux OS and also it is important to mention that the kernel of proxmox is based on Debian GNU and remember to enable the CPU utilization for virtualization before installing the OS.
• download link: https://www.proxmox.com/en/downloads
    • if needed pay attention to Paritioning the storage and file system. it should be suited for your corporation usage.
    • if FQDN is available it is recommended to use that too.
• pve-nag-buster: https://github.com/foundObjects/pve-nag-buster/
• remember to update packages after installation from (host-name) -> Updates -> and update field.
note
> custmoized repositories can be added to repository file as well.



### web console Overview
we have a DataCenter which all Proxmox hosts and storage goes under it.
for checking each host we need to click on them to check their resource and setting

note:
> remember that changing configuration on DataCenter dashboard will overwrite all other configuration on children hosts.

### Virtual Machine vs Containers
it is possible to run Containers (LXC) beside Virtual Machines in Proxmox also it is possible to make a template from container or even download a template of a Container.

remember that Containers are not able to be lived migrated but virtual computers are able.

#### Notes for Creating Virtual Machines
###### General section
• VMID can be changed manually and also can be used for condition that we are going to segmentize our vms into groups or type or even make them distiguishable form Containers.
• Start/Shutdown order: is used for condition where the database has priority to boot up from computers (advanced mode should be checked)

###### System:
• Qemu Agent:  If you plan to install the QEMU Guest Agent, or if your selected ISO image already ships and installs it automatically, you may want to tick the QEMU Agent box, which lets Proxmox VE know that it can use its features to show some more information, and complete some actions (for example, shutdown or snapshots) more intelligently.

###### Disks:
• Discard: With Discard set and a TRIM-enabled guest OS, when the VM’s filesystem marks blocks as unused after deleting files, the controller will relay this information to the storage, which will then shrink the disk image accordingly.
if your server has SSD it is recommended to check Discard in storage setting. but if HDD is available it needs considerations.


##### After Setup (Virtual Machine Dashbaord):
###### Options:
in option tab we have the QEMU Guest Agent which is used as a kittool for access inside virtual machine.

• side note
> in virtual machine we ca check `cat /proc/cpuinfo` to see the cpu utilization

• QEMU Guenst Agent: to have qemu agent on linux based system, they need to be installed. for example:
in newly created ubuntu vm do `sudo apt install qemu-guest-agent` to install its packages.
    - then start the service.
    - after service is started we need to change the Virtual machine in options > QEMU Guest Agent, and set it to enable.



#### Installing windows
for isntalling windows on Proxmox we need to include `virtio-win.iso` file which is addition driver packages for preparing windows
    • In Virtual Machine > System > SCSI Controller: the `VirtIO SCSI` needs to be selected
    • Hard Disk: it is also recommended to select `write back` option for cache due to improvement of performance.
- Caution:
for installing addition Packages, before booting up the Virtual Machine, add another CD-rom and add the virtio-win.iso file.
    • in installation process of windows, we also need to add the driver in wizard as well. and sometimes after the installation and inside the device manager dashboard.



### Containers on Proxmox (LXC)
in container creating the node actually refers to the host.
for running an LXC container on Proxmox we need to have template of that container, there are either uploading and using the template or downloading that template from the repository. 
to download a template we can go to:
Local/Storage pool > CT Templates > Download from URL or Templates

• Caution:
> Unprivilege containers are more safer because they don't have access to the root directory file system due to User Mapping. so be aware of that. 



### Taking template from Containers:
 before converting a container into a template there are few steps that need to be taken
• packages:remember to update the packages inside the container and do `sudo apt clean`. and `sudo apt autoremove` before taking template 
• ssh: we also need to delete ssh configuration keys
    - after removing ssh file we use `dpkg-reconfigure openssh-server` in order to reconfigure the ssh service on our container
• machine ID: we can use `sudo truncate -s 0 /etc/machine-id`

`cloud-init` package is also used by proxmox to handle duplication but it is not preinstalled on containers.



### User Management
###### User
User Management for whole of the Data Center is achieved in:
- Datacenter > Permissions > Users:

Pam in realm stands for the linux authentication protocols and host system itself. the different between `pam` user and `proxmox` user is where the data is stored for users
difference of pam and proxmox ve user:
• pam: is the user that created for the host itself, for instance the pam user (can) exist in /etc/shadow file (but needs configuration) and can use ssh to connect to the host. also after creating a pam user we need ot create it in host OS as well via `adduser (usrname)` command.
• proxmox ve: is the user that is stored inside the proxmox datacenter itself and for instance cannot perform ssh connection to hosts but they can connect via shell. 

###### Group
it is recommended to create a group before assigning any role and permission to users, because in this case we can make the server more organized and propagated.

###### Roles, Permissions
after that we can assign roles and permissions to users or groups. we also can create customized roles and permissions.



### Backup & Snapshot
difference of backup and snapshot: the backup is separated from the machine and can moved to other hosts but the snapshot is attached to the machine itself.
the RAM checkbox: in the snapshot the RAM check box is for including the changes that are present inside the ram as well.

Back up Jobs:
in Datacenter > Backup. we can define backup job for each machine and let us to make automation over backup.
    - the options are vary.



### Integrated Firewall
note:
> Remember that firewall setting can affect on console connection to proxmox

there is three layer of firewall in proxmox:
1. is for datacenter itself.
2. for each hosts
3. for virtualmachines and containers
the overwrite is from bottom to top

- • Important
if firewall is enabled and your connection is lost you can disable it only by kvm or direct console access:
in `/etc/pve/firewall/cluster.fw` then set `enable=` to 0
thus before enabling firewall remember to add rules and then enable the firewall on hosts.

to add new rules:
Firewall > Add (button)
Inputs specifications:
- Source IP, Destination: 192.168.2.12/32
- Direction, Action, Interface



### Command-Line Interface

##### qm command
` qm ` is mostly used for virtual machine manager. use `man qm` to see full document on OS.
common qm commands:
` qm list `: to list all virtual machines
` qm shutdown/start (VMID) `: to start or stop a machine based on its VMID
` qm reboot (VMID) `: to reboot virtual machine
` qm reset (VMID) `: its a ungraceful way to reset a machine when its not responsive (can be destructive)
` qm config (VMID) `: will list the configuration of a machine on terminal
` qm config (VMID) | grep (cpu) ` : to grep at specific field.

- we also can change option setting for each machine:
` qm set --onboot 0/1 (VMID) ` : it sets the onboot start of the machine to false/true.
` qm set --memory 2048 (VMID) ` : to change the memory of a machine

> check `man` page for more options

##### pct command
` pct ` is used to manage linux containers. to use it check out `man pct` page for more documentation.
` pct list `: to list all Containers
` pct shutdown/start (CTID) `: to start or stop a Container based on its CTID
` pct reboot (CTID) `: to reboot Container
` pct reset (CTID) `: its a ungraceful way to reset a Container when its not responsive (can be destructive)
` pct config (CTID) `: will list the configuration of a Container on terminal
` pct config (CTID) | grep (cpu) ` : to grep at specific field.

- we also can change option setting for each Container:
` pct set (CTID) -onboot 0/1  ` : it sets the onboot start of the Container to false/true.
` pct set (CTID) -memory 2048 ` : to change the memory of a Container

` pct enter (CTID) `: to enter into the Cotainer CLI




### Networking
##### Separating VM networks from management
It is essential to keep Management Network Separated from VM machines network which in our case we call it IO.
to do that we need to have separate network interfaces connected to our hosts and then define Linux Bridges over them.

to create a bridge:
first we go to (host) > System > Network > Create > select Linux Bridge.
for key and values we do:
IPv4/CIDR: This is the range of IP that we are going to pass traffic from inside of it for instance 192.168.1.0/24
Gateway: we need to define a gateway for it. (note that if there is a gateway for other interfaces inside the same network we can keep it blank)
Bridge port: we need to choose the interface that is being connected to our machine for example (ens34)

after changes we need to `apply Configuration` (its a button).

after that we need to assign new network interface to machines and by that we separate the network interface from machines.



### Shared Storage
we can dedicate shared storage pool for each host and vms. to do that we need to first define the location and storage pool and the way that this storage pool is accessible.

to add new storage/storage pool go to:
• Datacenter > Storage > Add Button.

for ourcase we are going to add storage over network which is NFS.
• Datacenter > Storage > Add Button > NFS.
- ID: we need to define an ID for it which it can be name to distinguish
- Server: IP address or FQDN of the storage pool
- Export: The directory or path on the storage pool dedicate for our host. for example /pool/backup-ve/

after storage creation we can now use them instead for storing vm files or backup and ISOs.



### Clustering
in creating a proxmox cluster for it we need to define the cluster on the Datacenter dashboard.
also consider that all host have to be able to see each other and firewall should be properly set.

to create new cluster:
go do Datacenter Dashboard > Cluster > Create Cluster > 
• Choose name for cluster 
• select the interface IP address. or multiple network if we have other network subnets.

then by sharing Join Information Link we are able to join other hosts to our cluster.

in the password section you should enter the host password that is stablishing the Cluster.



### High Availability (HA)
it is recommended to have 3 servers to establish the HA because of few reasons.
1. the hosts for example in 2 instance, will vote for themselves.
2. it is base to implement quorum which is a crucial mechanism in Proxmox HA that ensures only the majority of active nodes in a cluster can make important decisions

- also for HA we need to have shared storage pool which all the hosts and machines are inside of it.

we need to add each machine to the HA:
we can either add group of hosts to the HA or add machines one by one
Datacenter Dashboard > HA > Groups or HA



###



























Topics for further Documentation
> ZFS, Ceph and Directories in Proxmox host
> Datacenter: ACME, SDN, HA,  






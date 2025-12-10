# Openstack Deployment With Kolla-Ansible - All in One

## prerequisites

### Check OS Virtualization and OS Requirements
Kolla-Ansible Deployment on Single Node Requires at least:
- `8` CPU Core
- `16` GB of RAM
- `100` GB of Disk
- Intel VTL-X or AMD-V or SVM Mode Should be enabled which expose CPU hardware to internal machines
note:
> if CPU virtualization is not enbaled then Openstack will use QEMU which is extremely Slow.


### OS Network Hardwares
all-in-one node of kolla ansible needs to Interfaces, which one will be used for internal network and connection of each service and machines to outside and the other is going to have the floating IP and the IP address of own machine. the second interface will be in full control of kolla-ansible

Note: </br>
*If you are doing multi node deployment you would probebly need more interface. but for single node, two is sufficient.*

## Install Dependencies

1. update packages
- `sudo apt update`

2. install python packages
- `sudo apt install git python3-dev libffi-dev gcc libssl-dev libdbus-glib-1-dev`


### Install dependencies for the virtual environment¶
1. create virtual Environment
- `python3 -m venv /path/to/venv`
- `source /path/to/venv/bin/activate`

2. ennsure the latest versions
- `pip install -U pip`


## Install Kolla-Ansible
1. install kolla-ansible its dependencies usig `pip`:
- `pip install git+https://opendev.org/openstack/kolla-ansible@master`

2. Create the /etc/kolla directory
- `sudo mkdir -p /etc/kolla`
- `sudo chown $USER:$USER /etc/kolla`

3. Copy `globals.yml` and `passwords.yml` to `/etc/kolla` directory.
`cp -r /path/to/venv/share/kolla-ansible/etc_examples/kolla/* /etc/kolla`

4. Copy `all-in-one` inventory file to the current directory
- `cp /path/to/venv/share/kolla-ansible/ansible/inventory/all-in-one .`


### Install Ansible Galaxy requirements (if this step didn't work then follow the offline linux installation)
Install Ansible Galaxy dependencies:
- `kolla-ansible install-deps`


### Prepare initial configuration
Kolla Ansible comes with `all-in-one` and `multinode` example inventory files. The difference between them is that the former is ready for deploying single node OpenStack on localhost. In this guide we will show the `all-in-one` installation.


### Kolla passwords
Passwords used in our deployment are stored in `/etc/kolla/passwords.yml` file. All passwords are blank in this file and have to be filled either manually or by running random password generator:
- `kolla-genpwd`


### Kolla `globals.yml`
`globals.yml` is the main configuration file for Kolla Ansible and per default stored in `/etc/kolla/globals.yml` file. There are a few options that are required to deploy Kolla Ansible:

```yaml
kolla_base_distro: "ubuntu"
network_interface: "eth0" #This is the default interface for multiple management-type networks.
neutron_external_interface: "eth1" #This interface should be active without IP address. If not, instances won’t be able to access to the external networks
kolla_internal_vip_address: "172.31.11.159"  # If you use an existing OpenStack installation for your deployment, make sure the IP is allowed in the configuration of your VM.
```


### Additionals
#### `globals.d/` configuration
For a more granular control, enabling any option from the main `globals.yml` file can now be done using multiple yml files. Simply, create a directory called `globals.d` under `/etc/kolla/` and place all the relevant `*.yml` files in there. The kolla-ansible script will, automatically, add all of them as arguments to the ansible-playbook command.


`vim /etc/kolla/globals.d/cinder.yml`
```yml
enable_cider: "yes"
```


## Deploying Openstack Services and Dockers
1. use `bootstrap-servers` to prepare the machine for openstack deployment. it uses ansible to install docker, get all the python dependencies, install system tools, configure package repositories, create users and groups that openstack needs, setup ssh key for communication, tune kernel parameters for performance, create directories and so on. (it is the first big checkpoint)
- `kolla-ansible bootstrap-servers -i all-in-one` 

2. use `prechecks` to verify if ssh is working, packages are installed, validate system settings, memory and disk space, makes sure the network interfaces are configured and checks prerequisite services. it caches misconfigurations before installing any thing. actually a Sanity Check.
- `kolla-ansible prechecks -i all-in-one`

3. Kolla-ansible `deploy` will be used to orchestrate the openstack services deployment. it uses `globals.yml`. 
- `kolla-ansible deploy -i all-in-one`



## Interactive with Openstack
we can interact with Openstack via CLI, Web Interface and API. in this scenario we are going to prepare CLI interface:

1. install openstack command line in python virtual environment
- `pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/master`

2. OpenStack requires a `clouds.yaml` file where credentials for the admin user are set. it will be saved in `/etc/kolla/clouds.yaml`
- `kolla-ansible post-deploy -i all-in-one`

3. you can use `clouds.yaml` by copying it to `/etc/openstack` or `~/.config/openstack`, or by setting the `OS_CLIENT_CONFIG_FILE` environment variable.
- `mkdir -p ~/.config/openstack; cp /etc/kolla/clouds.yaml ~/.config/openstack`

4. we can use `OS_CLOUD` environment which tells openstack CLI which cloud config to use from the cloud YAML file
    1. `vim .bashrc`
    ```sh
    export OS_CLOUD=kolla-admin #corresponds to a named section or cloud entry within clouds.yaml
    source ~/your-virtual-environment/bin/activate
    ```

    2. add our user to docker group to use docker command without sudo 
    - `sudo usermod -aG docker $USER` 

    3. **close your terminal** and re-open it and verify if you can use openstack CLI
    - `openstack compute service list`
    - `openstack service list`
    - `openstack network agent lsit`
    - `openstack volume service list`
    - `docker ps -a`

5. check if horizon dashboard is working.
    1. first extract the password by greping it from password or cloud file
    - `grep keystone_admin_password /etc/kolla/passwords.yml`
    
    2. go to your web browser and type the VIP of openstack range IP  

### Example Kolla-Ansible Cluster Script
Depending on how you installed Kolla Ansible, there is a script that will create example networks, images, and so on. but this script can be modified.

1. copy the file and modify based on your cluster needs:
- `cp vbox/share/kolla-ansible/init-runonce .`
- `vim init-runonce`
```ini
#This EXT_NET_CIDR is your public network,that you want to connect to the internet via
ENABLE_EXT_NET=${ENABLE_EXT_NET:-1}
EXT_NET_CIDR=${EXT_NET_CIDR:-'172.31.11.0/24'}
EXT_NET_RANGE=${EXT_NET_RANGE:-'start=172.31.11.160,end=172.31.11.170'}
EXT_NET_GATEWAY=${EXT_NET_GATEWAY:-'172.31.11.254'}
```




---

# Openstack Network (Neutron)

## Neutron Architecture
Neutron is an OpenStack project to provide "networking as a service" between interface devices (e.g., vNICs) managed by other Openstack services (e.g., nova).
Neutron gives cloud tenants an API to build rich networking topologies, and configure advanced network policies in the cloud. for example create multi-tier web application topology.


### neutron-server
neutron-server provides a webserver that exposes the Neutron API, and passes all web service calls to the Neutron plugin for processing. in our kolla ansible project we are running Neutron service in a docker container. you can verify it via:
- `docker ps | grep neutron-server` => it will list all service that has been run via `neutron-server`
- `docker ps | grep neutron_server`


### Modular Layer 2 (ML2) Architecture Neutron ([ML2 Plug-in](https://docs.openstack.org/neutron/latest/admin/config-ml2.html))
The Modular Layer 2 (ML2) neutron plug-in is a framework allowing OpenStack Networking to simultaneously use the variety of layer 2 networking technologies found in complex real-world data centers. The ML2 framework distinguishes between the two kinds of drivers that can be configured. </br>

to check drivers and configs of ml2 in neutron service we can check it in docker via:
- `docker exec -it neutron_server cat /etc/neutron/plugins/ml2/ml2_conf.ini`


### network services

to check all related process such as openvswitch, l3, l3-agent by hosts via:
- `openstack network agent list -c Host -c Binary`

we can list docker containers via:
- `docker ps | grep neutron`


### openvswitch
we might want to run network services such as DHCP or L3 Routing on other machines but how can each compute node find out how to route its network traffic? thats where we use openvswtich and ovs-agent. they are responsible for managing the local virtual swtich and connect them in to other nodes because ovs agent is interacting in layer 2 so each compute node can send broadcast message to receive service or connection. we can confirm its running contaner via: </br>

- `docker ps | grep openvswitch`


### ovs-agent ([Open vSwitch L2 Agent](https://docs.openstack.org/neutron/latest/contributor/internals/openvswitch_agent.html))
ovs-neutron-agent can be configured to use different networking technologies to create project isolation. These technologies are implemented as ML2 type drivers which are used in conjunction with the Open vSwitch mechanism driver.


#### ovs agent firewall capability ([Open vSwitch Firewall Driver](https://docs.openstack.org/neutron/latest/contributor/internals/openvswitch_firewall.html))
ovs is not only used for layer 2 capability but it is also responsible for access rules and security enforcing. the ovs-agent uses `iptables` as its own `firewall_driver` check out the drivers by: </br>
- `docker exec -it neutron_openvswitch_agent cat /etc/neutron/plugins/ml2/openvswitch_agent.ini` 

`iptables` as a driver adds complexity and performance overhead. another option for that is `openvswitch`.


### openvswitch firewall
the `openvswitch` driver is the native and more cleanr and more efficient approach for applying firewall security. for better performance we can reconfigure our `kolla-ansible` configuration to use native ovs firewall. we do this by adding custome configuration file that kolla ansbile will override the default setting.

1. create a directory for new neutron configuration file.
- `mkdir -p /etc/kolla/config/neutron`

2. add the new `openvswitch_agent.ini` to the configuration file and change to `firewall_driver` to `openvswitch`
- `vim /etc/kolla/config/neutron/openvswitch_agent.ini`

``` ini
[securitygroup]
firewall_driver = openvswitch

```

3. run the kolla-ansible deployment playbook to apply new configuration
- `kolla-ansible deploy -i all-in-one`


### Tenant Network and Provider Network

#### 1. Tenant Network
think of it as your own private project scope network space. Tenant networks are created by users and Neutron is configured to automatically select a network segmentation type like VXLAN or VLAN. The user cannot select the segmentation type. these are called overlay network which it means that they run over the existing physical networks. openstack achieve this through encapsulation. you can create these virtual network without need for network teams to be envolved

#### 2. Provider networks 
provider network is a direct bridge to a physical network that already exists outside of openstack cloud. these are created by administrators, that can set one or more of the following attributes: </br>
Segmentation type (flat, VLAN, Geneve, VXLAN, GRE) </br>
Segmentation ID (VLAN ID, tunnel ID) </br>
Physical network tag </br>
Any attributes not specified will be filled in by Neutron. </br>


### Network and Subnet Configuration
for 2 different vms to communication, they first need a common network. the openstack network will act as a distributed layer between 2 VMs. to do that lets create a network

1. create a network
- `openstack network create <name-of-network>`

2. create a subnet which belongs to the created network and define IP address pool and dns server.
- `openstack subnet create --network <name-of-network> --subnet-range 192.168.1.0/24 --gateway 192.168.1.254 --dns-nameserver 8.8.8.8 <name-of-subnet`

in openstack, VMs don't connect directly to the network, they connect through ports which are like virtual network plug. a port holds the MAC address, IP address, and security.

we can list our ports in openstack via:
- `openstack port list`

inpsect the port s device owner via:
- `openstack port show <ID> -c device_owner`

inspect dhcp provder nodes
- `openstack network agent list --agent-type dhcp`


#### how does dhcp agent connect to networks?
it uses the `namespaces` which is a linux feature. it is an isolated copy of the networking stack with its own interfaces, routing tables and firewall rules. </br>
to list networking namepsaces we use:
- `ip netns`

for interacting inside dhcp node we use `exec -it` switch:
- `ip netns exec <qdhcp-ip> bash`

inside the dhcp node, use `ip add` to see interfaces. to check the interface.

and then to check `dnsmasq` to see which interface it is using
- `ps -ef | grep dnsmasq`


### creating dedicated port for virtual machines
after establishing, network, a subnet and dhcp service, we can create a dedicated port for creating VMs. 
- `openstack port create --network <network-name> --fixed-ip subnet=<subnet-name>,ip-address=192.168.1.1 <port-name>` 
note: 
> if you don't specific the `ip-address` the ip will be applied automatically from subnet.
> also if the port is not defined for any VM its status will be DOWN.


#### Create a new machine with create network
after establishing the network and ports we can create machine and assign the network port to that.
- `openstack server create --flavor m1.tiny --image cirros --port <port-name> <vm-name>`  

check the ports again to see if the created port is `UP`:
- `openstack port list --long`

 

### OVS Bridge
its a software based virtual switch. it connects different network interfaces like network tunnels, physical NICs and VM interfaces. ovs uses **three distinct bridges** on each network node to separate and manage different types of traffic. </br>
to identify and list it:
- `docker exec -it openvswitch_db ovs-vsctl show` this command will list data related to 1. integration bridge

1. **intergration bridge (`Bridge br-int`)**: this is the central hub. all virtual network interfaces for your VM connect to dhcp server and virtual routers and etc.
2. Port 
 



---
## how to install kolla-ansible on offline linux server. (403 Error)

### 1.download required packages on internet-connected machine

keep in mind that these steps should be completed after [the previous kolla-ansible steps](https://docs.openstack.org/kolla-ansible/latest/user/quickstart.html#install-dependencies).

0. install required packages:
- `sudo apt install git python3-dev libffi-dev gcc libssl-dev libdbus-glib-1-dev`

1. create a virtual environment and run ansible-galaxy in it
    0. `sudo apt install python3-venv`
    1. `python3 -m venv /path/to/venv && source /path/to/venv/bin/activate`
    2. `pip install -U pip`

2. install kolla-ansible packages in environment
- `pip install git+https://opendev.org/openstack/kolla-ansible@master`

3. create another directory to hold the offline packages
    0. `mkdir ansible-offline; cd ansible-offline`

4. download packages (keep in mind that `-r` switch will iterrate through `requirment-core.yml` file and download the requirement packages in `.tar.gz` file (tarball))
- `ansible-galaxy collection download -r ../venv/share/kolla-ansible/requirements-core.yml`

5. then zip the download files (which its name is collection by default)
- `zip -r collections.zip ./collections/`

6. scp the file to the offline server 
- `scp username@172.123.123.12:/your-own/directory`


### 2. install the downloaded `.tar.gz` file on offline host

0. cd or move the directory to the defined location and remember to enable the virtual environemnt ([guide](https://docs.openstack.org/kolla-ansible/latest/user/quickstart.html#install-dependencies-for-the-virtual-environment))
- `unzip collection.zip; cd collection/` => u will see the `.tar` file and a `requirement.yml` file

1. install packages via `ansible-galaxy`
- `ansible-galaxy collection install -r requirements.yml`


### 3. Installing Required Libraries to Virtual Environment

in virtual environment, install the required packages with python package manager (`pip`):
- `pip install docker`
- `python -c "import docker; print(docker.version)"`
- `apt install -y libdbus-1-dev libdbus-glib-1-dev pkg-config`
- `pip install dbus-python`
- `python -c "import dbus;"`


#### Generate Password:
Passwords used in our deployment are stored in /etc/kolla/passwords.yml file. All passwords are blank in this file and have to be filled either manually or by running random password generator:
- `kolla-genpwd`

#### change `globals.yml`

```yaml
kolla_base_distro: "ubuntu"
network_interface: "eth0":
neutron_external_interface: "enp6s19"
kolla_internal_vip_address: "172.31.11.159"
```

#### Deploy the Openstack Containers
1. Bootstrap servers with kolla deploy dependencies:
- `kolla-ansible bootstrap-servers -i ./all-in-one`

2. Do pre-deployment checks for hosts:
- `kolla-ansible prechecks -i ./all-in-one`

3. Finally proceed to actual OpenStack deployment:
- `kolla-ansible deploy -i ./all-in-one`


#### Using Openstack
1. Install the OpenStack CLI client:
- `pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/master`

2. OpenStack requires a `clouds.yaml` file where credentials for the admin user are set. To generate this file:
- `kolla-ansible post-deploy`

3. Depending on how you installed Kolla Ansible, there is a script that will create example networks, images, and so on.
- `/path/to/venv/share/kolla-ansible/init-runonce`


### how to find password and users of each service
passwords are generated by `kolla-genpwd` and are held in `/etc/kolla/passwords.yml`. however these passwords are also generated via `kolla-ansible post-deploy`

- `grep keystone /etc/kolla/passwords.yml` => to grep password from passwords.yaml
- `grep keystone /etc/kolla/clouds.yml` => to grep passwords from clouds.yaml


### to destory the ansible based services
`kolla-ansible destroy -i all-in-one --yes-i-really-really-mean-it`


### troubleshooting the tasks that related to containers ([Troubleshooting Guide](https://docs.openstack.org/kolla-ansible/latest/user/troubleshooting.html))
if you have trouble with containers, it is recommended to pull the containers again:
- 1. `kolla-ansible pull -i all-in-one` =>  it will pull all 
- 2. `kolla-ansible deploy -i all-in-one` => attempt to deploy the ansible rolls again



---
# Technical Errors 

#### Something Went Wrong Error
![something-went-image](https://cloud.githubusercontent.com/assets/1716020/19098337/a7852a7a-8aac-11e6-9faa-12e4baf15887.png)

solved this issue by restarting relative docker containers. and checking their health and logs 
0. to list all containers and check their health 
- `sudo docker ps -a`
1. check status logs for relative containers
- `sudo docker logs <container_name>`
2. to restart the culprit container
- `sudo docker container restart <container_name>`. in my case  
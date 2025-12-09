

---
### Creating VM in Proxmox Dashboard 
### 1.Steps and Parameter to consider when creating vm for "cloud-init Template" ([Youtube Link](https://www.youtube.com/watch?v=1Ec0Vg5be4s))
0. Select "Create Machine"
1. in General section
    1. set VM ID (1000)
    2. choose Node
    3. Set a Name (ubuntu-cloudinit)
2. in OS
    1. Select "Do not use any Media" (because we are going to add from cloud-init image)
3. in System
    1. set Machine as `q35`
    2. set BIOS to `OVFM (UEFI)`
        1. Select the EFI Storage `local-lvm` (depends on your proxmox storage)
    3. check the Qemu Agent box
    4. be sure Display is set to default
4. in Disk
    1. remove any disk (we are going to add cloud-init)
5. in CPU
    1. set the minimum if you want (no change is required)
6. in Memory
    1. set to minimum `1024` (no change is required)
7. in Network
    1. no change is required (just make sure of bridge and model)
8. in Confirm 
    1. uncheck the start after created

### 2.Add cloud-init and attach the cloud-init drive to the machine:
1. first download the cloud-init image on your `pve` host.
- `wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img`
2. rename the image to `qcow2` for better storage efficiency through thin provisioning and snapshots.
- `mv noble-server-cloudimg-amd64.img noble-server-cloudimg-amd64.qcow2`
3. expand the virtual image before you resize the partition inside the guest OS to use the new space. 
- `qemu-img resize noble-server-cloudimg-amd64.qcow2 5G`
4. import the modified disk to the created machine in **step 1**
- `qm importdisk <vm-id> <image-cloud.qcow2> <local-lvm> `
5. also set the serial socker ang vga so we can use console for our machine
- `qm set 1000 --serial0 socket --vga serial0`
6. on the machine with related ID. add `cloud-init` driver and also add the Unused Disk
7. add CloudInit Driver and add the Desired Storage
8. in cloud-init template > options > change the boot order to scsi0 


---
### Creating VM in Proxmox CLI

#### 1. SSH into your Proxmox node
- `ssh -v root@your-proxmox-ip`

#### 2. Download image
- `cd /var/lib/vz/template/qemu`
- `wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img`

#### 3. Create VM
- `qm create 1000 --name "Ubuntu-Noble-CloudInit-Template" --memory 1024 --cores 1 --sockets 1 --net0 virtio,bridge=vmbr0 --serial0 socket --cpu host --bios ovmf --machine q35 --ostype l26`

#### 4. Import disk
- `qm importdisk 1000 /var/lib/vz/template/qemu/noble-server-cloudimg-amd64.img local-lvm`

#### 5. Configure disk and boot order
- `qm set 1000 --scsi0 local-lvm:vm-1000-disk-0 --boot order=scsi0 --ide2 local-lvm:cloudinit`

#### 6. Configure cloud-init
- `qm set 1000 --ipconfig0 "ip=172.24.24.1/24,gw=172.24.24.254" --ciuser ubuntu --cipassword ubuntu`

#### 7. Resize disk
- `qm resize 1000 scsi0 +20G`

#### 8. Convert to template
- `qm template 1000`

#### 9. Verify
- `qm list | grep 1000`


---
### DHCP Configuration in Proxmox

1. Create a Simple SDN Zone:
- Navigate to your datacenter's "SDN" tab.
- Create a new "Zone" and choose "Simple" as the type.
2. Give it a name (e.g., SimpleZone).
- Enable "Automatic DHCP" and set the "IPAM" to "PVE" in the advanced settings.
- Add a "SNAT" option if you want VMs to have internet access.
3. Create a VNet and Subnet:
- Inside your new zone, create a "VNet" (virtual network).
- Define an IPv4 and/or IPv6 subnet, including the IP range and gateway.
- Specify a DHCP range within the subnet to define the pool of addresses to be assigned automatically.
4. Connect VMs to the VNet:
- When creating a new VM or editing an existing one, go to the "Network" configuration.
- Select the VNet you just created as the bridge.
- Set the IPv4 and/or IPv6 configuration to "DHCP" within the VM's network settings.
5. Troubleshoot DHCP:
- If DHCP doesn't work immediately, reboot the VM or the Proxmox host.
- For a running VM, reloading its network stack is often sufficient.
- Check the system logs for any errors related to dnsmasq.
- Ensure that your firewall is not blocking DHCP (UDP port 67) or DNS (UDP port 53) traffic, as mentioned on Reddit. 



---
### VNET error while deleting sdn subnet 
- `delete sdn subnet object failed: cannot delete subnet '172.31.11.0/24', not empty (500) proxmox`

to fix this error make sure that in `Datacenter` > `SDN` > `IPAM` there is no IP related to your network configuration. there is no need to delete all sdn configuration in `etc/pve/sdn/*`


---
### How to Create SDN Based DHCP in Proxmox (without VLAN) with Simple Zone SDN
The **Simple Zone** natively supports the **built-in DHCP/IPAM** feature, but it creates an isolated Layer 3 routing bridge that is not VLAN-aware. It is intended for creating isolated networks on a per-node basis (with optional SNAT for Internet access). </br>
The **VLAN Zone** type is designed to connect to your physical infrastructure and be VLAN-aware, but historically and currently, it does not support the automatic DHCP/IPAM plugin.

#### 1. Prerequisites (on all nodes)
1. install `dnsmasq` </br>
- `apt update && apt install dnsmasq`
2. Disable the default `dnsmasq` service: Proxmox's SDN will manage its own instances. </br>
- `systemctl disable --now dnsmasq` 
3. Ensure the configuration line source `/etc/network/interfaces.d/*` is present 


#### 2. Configure the SDN Zone (Web UI)
1. Navigate to Datacenter $\rightarrow$ SDN $\rightarrow$ Zones.
2. Click Add and select the Simple type.
3. Set an ID (e.g., sdn-dhcp-simple).
4. In the Advanced settings, ensure automatic DHCP is checked. The default IPAM (IP Address Management) plugin is pve, which you should keep selected to enable DHCP.
5. Select the Nodes you want this zone to be available on (typically all of them in a cluster).


#### 3. Create the VNet and Subnet
*A VNet (Virtual Network) is a virtual bridge that belongs to a zone, and the Subnet defines the IP space, gateway, and DHCP range within that VNet.*

1. Navigate to Datacenter $\rightarrow$ SDN $\rightarrow$ VNets.
2. Click Create.
3. Set an ID for the VNet (e.g., vnet-corp). Note: The ID is often limited to 8 characters.
4. Select the Zone you created in the previous step (e.g., sdn-dhcp-simple).
5. Click Create.
1. Select your new VNet and, in the Subnets panel, click Create.
    - Subnet: Enter the network in CIDR notation (e.g., 10.10.100.0/24).
    - Gateway: Define the gateway IP (e.g., 10.10.100.1). **This IP will be assigned to the VNet interface on the Proxmox hosts and is necessary for DHCP to work**.
    - SNAT: Check the **SNAT** box if you want virtual machines on this network to be able to access your physical network and the internet using Network Address Translation (NAT) through the Proxmox host.
    - Go to the **DHCP Ranges** tab and click Add.
    - Enter the Start Address and End Address for your dynamic IP pool (e.g., 10.10.100.100 to 10.10.100.150).


#### 4. Apply the Configuration
1. Go back to the main Datacenter $\rightarrow$ SDN overview and Click the Apply button.


---

### Apply Network Changes on Proxmox Hosts ([Link](https://pve.proxmox.com/wiki/Network_Configuration))
If you made manual changes directly to the `/etc/network/interfaces` file, you can apply them by running `ifreload -a`


---

### ssh publickey error (ubuntu@192.168: Permission denied (publickey)):
When we try to connect to machines created by `cloud-init` with ssh, this error is given. The current solution is to change `PasswordAuthentication` to yes.

- `sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication  yes/' /etc/ssh/sshd\_config.d/60-cloudimg-settings.conf`
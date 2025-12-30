
# How Cloud-Init is Created For Devlab Project in Proxmox

## Method 1: Version 1: Creating basic cloud-img based VM for using as a Template:
in this template the whole machine is completely raw and no repository or packages is added. its just a bare Ubuntu 24.04 Noble Image.

### 1.Steps and Parameter to consider when creating vm for "cloud-init Template" in Proxmox UI ([Youtube Link](https://www.youtube.com/watch?v=1Ec0Vg5be4s))
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

### 2.Add cloud-init and attach the cloud-init drive to the machine in PVE Host:
1. first download the cloud-init image on your `pve` host.
- `wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img`
2. rename the image to `qcow2` for better storage efficiency through thin provisioning and snapshots.
- `mv noble-server-cloudimg-amd64.img noble-server-cloudimg-amd64.qcow2`
3. expand the virtual image before you resize the partition inside the guest OS to use the new space. 
- `qemu-img resize noble-server-cloudimg-amd64.qcow2 5G`
4. import the modified disk to the created machine in **step 1**
- `qm importdisk <vm-id> <image-cloud.qcow2> <local-lvm> `
5. also set the serial socket and vga so we can use console for our machine
- `qm set 1000 --serial0 socket --vga serial0`
6. on the machine with related ID. add `cloud-init` driver and also add the Unused Disk
7. add CloudInit Driver and add the Desired Storage
8. in cloud-init template > options > change the boot order to scsi0 



## Method 2: Version 1
in this scenario we are going to deploy a customized cloud-img file with local registry and updated packages.

1. download ubuntu image 
- `wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img`

2.
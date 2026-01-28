variable vm_configs {
    type =  map(object({
      #vm_id = number
      target_node = string
      clone = string
      name = string
      cores = number
      sockets = number
      memory = number
      disk_size = string
      vm_state = string 
      #network_tag = number 
      bridge = string
      onboot = bool
      startup = string
      ipconfig0 = string
      ciuser = string
      cipassword = string
    }))
    default = {
      "machines" = { 
        target_node = "pve1"
        clone = "ubuntu-cloudinit"
        name="mercede-v-srv1", 
        cores = 2,  
        sockets= 2, 
        memory = 4096, 
        disk_size = "40G"
        vm_state = "running", 
        #network_tag = 111, 
        bridge = "Vlan111",
        onboot = true, 
        startup = "order=2", 
        ipconfig0 = "ip=172.31.11.21/24,gw=172.31.11.254", 
        ciuser = "ubuntu" ,
        cipassword = "Aa123456" 
      }     
    }
  }

resource "proxmox_vm_qemu" "proxmox" {
  for_each = var.vm_configs

  name = each.value.name
  target_node = each.value.target_node
  
  clone = each.value.clone
  full_clone = false
  bios = "ovmf"
  agent = 1
  scsihw = "virtio-scsi-single"

  vm_state = each.value.vm_state
  onboot = each.value.onboot
  startup = each.value.startup

  # cloud-init parameters
  ipconfig0 = each.value.ipconfig0
  skip_ipv6 = true
  ciuser = each.value.ciuser
  cipassword =  each.value.cipassword

  os_type = "cloud-init"
  
  memory = each.value.memory

  cpu {
    sockets = each.value.sockets
    cores = each.value.cores
  }

  serial {
    id = 0
    type = "socket"
  }

  disks {
    scsi {
        scsi0 {
            disk {
                size = each.value.disk_size
                storage ="local-zfs"
                replicate = "true"
            }
        }
    }

    ide {
        ide2 {
            cloudinit {
              storage = "local-zfs"
            }
        }
    }
 }
 
  network {
    id = 0
    model = "virtio"
    bridge = each.value.bridge
    firewall = true
    #tag = each.value.network_tag
  }

}


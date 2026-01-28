variable vm_configs {
    type =  map(object({
      #vm_id = number
      name = string
      cores = number
      sockets = number
      memory = number
      vm_state = string 
    }))
    default = {
      "dev-1" = { name="dev-1", cores = 2, sockets= 1, memory = 4049, vm_state = "running" }
      "dev-2" = { name="dev-2", cores = 2, sockets= 1, memory = 4049, vm_state = "stopped" }
      "dev-3" = { name="dev-3", cores = 2, sockets= 1, memory = 4049, vm_state = "stopped" }
    }
}
resource "proxmox_vm_qemu" "proxmox" {
  for_each = var.vm_configs

  name = each.value.name
  target_node = "proxmox-test-srv2"
  
  #clone = "clone-name"
  #full_clone = false
  bios = "ovmf"
  agent = 1
  vm_state = each.value.vm_state
  os_type = "ubuntu"
  
  memory = each.value.memory

  cpu {
    sockets = 1
    cores = 2
  }

  disks {
    scsi {
        scsi0 {
            disk {
                size = "20G"
                storage ="local-zfs"
            }
        }
    }
    ide {
        ide2 {
            cdrom {
                iso = "local:iso/ubuntu-24.04-live-server-amd64.iso"
            }
        }
    }
 }
 
}


resource "proxmox_vm_qemu" "production" {
  name = "terraform-commit"
  target_node = "proxmox-test-srv2"
  clone = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

  agent = 1
  full_clone = false
  bios = "ovmf"

  os_type = "ubuntu"

  cpu {
    sockets = 1
    cores = 2
  }

  memory = 4096 

  disks {
    scsi {
        scsi0 {
            disk {
                size = "20G"
                storage = "local"
            }
        }
    }
  }
   
  # Network configuration
  network {
    id = 1
    model  = "virtio"
    bridge = "vmbr1"
  }
  
}
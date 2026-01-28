variable "vm_base_config" {
  type = object({
    target_node = string
    clone = string
    name_prefix = string
    cores = number
    sockets = number
    memory = number
    disk_1_size = string
    disk_2_size = string
    vm_state = string 
    bridge = string
    #onboot = bool
    #startup_order_base = number
    nameserver = string
    ip_base = string
    ip_gw = string
    ip_start_offset = number
    ciuser = string
    cipassword = string
    sshkeys = string
  })
  
  default = {
    target_node = "pve5"
    clone = "ubuntu-cloudinit-v2"
    name_prefix = "mohammadreza-v-srv" #change this name base on your machine clustser  it is going to iterate through number of machines (example test-v-srv1, test-v-srv2, ...)
    cores = 4
    sockets = 2 
    memory = 4096
    disk_1_size = "50G" #Disk going to be used for OS
    disk_2_size = "100G" #this disk is going to be used as unmounted Disk Space        
    vm_state = "stopped"
    bridge = "Vlan111"
    #onboot = true
    #startup_order_base = 2
    nameserver = "8.8.8.8"
    ip_base = "172.31.11.0/24"
    ip_gw = "172.31.11.254"
    ip_start_offset = 151 #change this IP offset for each Collaborator Range IP  and it will be increased based on number of machines (example 172.31.11.51, 172.31.11.52, ...)
    ciuser = "ubuntu"
    cipassword = "Aa123456" 
    sshkeys = "" # add your ssh key to be used inside each machine
  }
}

variable "vm_count" {
  default = 8 # change this based on number of machines you need.
}

resource "proxmox_vm_qemu" "proxmox" {
  count = var.vm_count
  
  name = "${var.vm_base_config.name_prefix}${count.index + 1}"
  target_node = var.vm_base_config.target_node
  
  clone = var.vm_base_config.clone
  full_clone = false
  bios = "ovmf"
  agent = 1
  scsihw = "virtio-scsi-single"

  vm_state = var.vm_base_config.vm_state
  #onboot = var.vm_base_config.onboot
  #startup = "order=${var.vm_base_config.startup_order_base + count.index}"

  # cloud-init parameters
  ipconfig0 = "ip=${cidrhost(var.vm_base_config.ip_base, var.vm_base_config.ip_start_offset + count.index)}/24,gw=${var.vm_base_config.ip_gw}"
  nameserver = var.vm_base_config.nameserver
  skip_ipv6 = true
  ciuser = var.vm_base_config.ciuser
  cipassword = var.vm_base_config.cipassword
  sshkeys = var.vm_base_config.sshkeys

  os_type = "cloud-init"
  
  memory = var.vm_base_config.memory

  cpu {
    sockets = var.vm_base_config.sockets
    cores = var.vm_base_config.cores
  }

  serial {
    id = 0
    type = "socket"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          size = var.vm_base_config.disk_1_size
          storage = "RBD"
          replicate = "true"
        }
      }
      scsi1 {   # second disk which is unmounted disk
        disk {
          size = var.vm_base_config.disk_2_size
          storage = "RBD"
          replicate = "true"
        }
      }
    }

    ide {
      ide2 {
        cloudinit {
          storage = "RBD"
        }
      }
    }
  }
 
  network {
    id = 0
    model = "virtio"
    bridge = var.vm_base_config.bridge
    firewall = true
  }
}
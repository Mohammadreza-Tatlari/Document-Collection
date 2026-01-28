resource "proxmox_lxc" "basic" {
  target_node  = "proxmox-test-srv2"
  hostname     = "lxc-basic"
  ostemplate   = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  password     = "Aa123456"
  unprivileged = true
  onboot = true
  start = true

  
  // Terraform will crash without rootfs defined
  rootfs {
    storage = "local-zfs"
    size    = "4G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr1"
    ip     = "172.24.24.15/32"
    gw     = "172.24.24.254"
    tag    = "424"
  }
  
  nameserver ="172.24.20.2, 172.24.20.1"
}
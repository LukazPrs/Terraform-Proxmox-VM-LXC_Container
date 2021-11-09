terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.0"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://192.168.30.5:8006/api2/json"
  pm_api_token_id = "terraform@pam!TOKEN_TF"
  pm_api_token_secret = "TOKEN_SECRET"
  pm_tls_insecure = true
}
 
### Criando VM ubuntu
resource "proxmox_vm_qemu" "test_server" {
  count = 1   # uma vm
  ciuser = "ubuntu"
  cipassword = var.mv_password

  name = "TERRAFORM-VM-${count.index + 1}" 
  desc = "VM Terraform"
  target_node = var.proxmox_host
  clone = var.template_name
  full_clone = true
  #agent = 1
  os_type = "cloud-init"
  cores = 2
  sockets = 1
  cpu = "host"
  memory = 2048
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  disk {
    slot = 0
    size = "10G"
    type = "scsi"
    storage = "storage0"
    iothread = 1
  }

  # duplicar esta opção para usar 2NICs
  network {
    model = "virtio"
    bridge = "vmbr0"
    macaddr   = "FA:C0:38:4F:DB:BF"
  }

  #ipconfig0 = "ip=10.98.1.9${count.index + 1}/24,gw=10.98.1.1"
  ipconfig0 = "ip=192.168.30.151/24,gw=192.168.30.1"

  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
 
  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}

### Criando container lxc
resource "proxmox_lxc" "terraform-lxc" {
  target_node  = var.proxmox_host
  hostname     = "TERRAFORM-LXC02"
  ostemplate   = "local:vztmpl/ubuntu-20.04-standard_20.04-1_amd64.tar.gz"
  password     = "12345"
  unprivileged = true

  memory = 256
  onboot = true
  start = true
  cores = 1

  ssh_public_keys = <<EOF
  ${var.ssh_key}
  EOF

  rootfs {
    storage = "storage0"
    size    = "4G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
    hwaddr = "FA:C0:38:4F:DB:BA"
  }
}

terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.1-rc9"
    }
  }
}

provider "proxmox" {
  # url is the hostname (FQDN if you have one) for the proxmox host you'd like to connect to to issue the commands. my proxmox host is 'prox-1u'. Add /api2/json at the end for the API
  pm_api_url = "https://192.168.0.106:8006/api2/json"
  # api token id is in the form of: <username>@pam!<tokenId>
  pm_api_token_id = "terraform-prov@pve!terraform"
  # this is the full secret wrapped in quotes. don't worry, I've already deleted this from my proxmox cluster by the time you read this post
  pm_api_token_secret = "******""
  # leave tls_insecure set to true unless you have your proxmox SSL certificate situation fully sorted out (if you do, you will know)
  pm_tls_insecure = true
}

# resource is formatted to be "[type]" "[entity_name]" so in this case
# we are looking to create a proxmox_vm_qemu entity named test_server
resource "proxmox_vm_qemu" "virt" {
  count = 1
  name = "virt-${count.index + 1}"
  vmid = "${count.index+1165}"
  target_node = "${var.proxmox_host}"
  clone = "${var.template_name}"
  define_connection_info = true
  agent = 1
  os_type = "cloud-init"
 # cpu {
 #   cores = 2
 #   sockets = 1
 #   type = "host"
 # }
  
  memory = 2048
  sshkeys = "${var.ssh_key}"
  scsihw = "virtio-scsi-pci"
  #bootdisk = "scsi0"
  ciuser = "ubuntu"
  cipassword = "******""
  ipconfig0 = "ip=192.168.31.${count.index + 70}/24,gw=192.168.31.1"

  boot = "order=scsi0"

  serial {
        id   = 0
        type = "socket"
    }

  disks {
      ide {
          ide2 {
              cloudinit {
                  storage = "local-lvm"
              }
          }
      }
      scsi {
          scsi0 {
              disk {
                  size            = 20
                  storage         = "local-lvm"
              }
          }
      }
  }

  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }
  # lifecycle {
  #   ignore_changes = [
  #     network,
  #   ]
  # }

  connection {
   type        = "ssh"
   user        = "ubuntu"
   private_key = file("./sshterraform")
   host        = self.ssh_host
   port        = self.ssh_port
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "export DEBIAN_FRONTEND=noninteractive",
      "export NEEDRESTART_MODE=a",
      "sudo -E apt -y upgrade"
    ]
  }

}
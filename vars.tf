variable "ssh_key" {
    type = string
    default = "ssh-rsa ******"

}
variable "proxmox_host" {
    default = "pve"
}
variable "template_name" {
    default = "ubuntu2404"
}
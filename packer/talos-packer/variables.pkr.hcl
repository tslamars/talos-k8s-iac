variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "proxmox_storage" {
  type = string
}

variable "cpu_type" {
  type    = string
  default = "kvm64"
}

variable "cores" {
  type    = string
  default = "2"
}

variable "cloudinit_storage_pool" {
  type    = string
  default = "zfsssd"
}

variable "talos_version" {
  type    = string
  default = "v1.9.4"
}

variable "base_iso_file" {
  type    = string
}

locals {
  image = "https://factory.talos.dev/image/dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586/${var.talos_version}/nocloud-amd64.raw.xz"
}
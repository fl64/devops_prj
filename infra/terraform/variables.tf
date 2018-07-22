variable project {
  description = "Project ID"
  default     = "devops-prj"
}

variable region {
  description = "Region"
  default     = "europe-west4"
}

variable zone {
  description = "Zone"
  default     = "europe-west4-a"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable machine_type {
  description = "Machine type"
  default     = "n1-standard-1"
}

variable disk_image {
  description = "Disk image"
  default     = "ubuntu-1604-lts"
}

variable disk_size {
  description = "Disk size"
  default     = "50"
}

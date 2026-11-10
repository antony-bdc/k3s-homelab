variable "tenancy_ocid" {
  description = "OCID of the tenancy. Used to look up availability domains."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment for all resources. Defaults to the tenancy (root compartment)."
  type        = string
  default     = null
}

variable "region" {
  description = "OCI region, e.g. eu-zurich-1."
  type        = string
  default     = "eu-zurich-1"
}

variable "oci_profile" {
  description = "Profile name in ~/.oci/config."
  type        = string
  default     = "DEFAULT"
}

variable "ssh_public_key" {
  description = "Public key that may log in as the ubuntu user."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) ", var.ssh_public_key))
    error_message = "ssh_public_key must be an OpenSSH public key (ssh-ed25519, ssh-rsa or ecdsa)."
  }
}

variable "admin_cidr" {
  description = "Only this range may reach SSH. Use your own address, e.g. 203.0.113.7/32."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a valid CIDR and must not be 0.0.0.0/0."
  }
}

variable "availability_domain_index" {
  description = "Which availability domain to use (0-based). Try another one if A1 capacity is exhausted."
  type        = number
  default     = 0
}

variable "k3s_version" {
  description = "k3s release, same as the local clusters."
  type        = string
  default     = "v1.31.5+k3s1"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+\\+k3s[0-9]+$", var.k3s_version))
    error_message = "k3s_version must look like v1.31.5+k3s1."
  }
}

variable "agent_count" {
  description = "Number of agent nodes next to the server."
  type        = number
  default     = 2

  validation {
    condition     = var.agent_count >= 0 && var.agent_count <= 3
    error_message = "agent_count must be between 0 and 3."
  }
}

variable "server_ocpus" {
  description = "OCPUs for the server node."
  type        = number
  default     = 2
}

variable "server_memory_gb" {
  description = "Memory in GB for the server node."
  type        = number
  default     = 12
}

variable "agent_ocpus" {
  description = "OCPUs per agent node."
  type        = number
  default     = 1
}

variable "agent_memory_gb" {
  description = "Memory in GB per agent node."
  type        = number
  default     = 6
}

variable "boot_volume_gb" {
  description = "Boot volume size per node (OCI minimum is 47 GB)."
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_gb >= 47
    error_message = "OCI boot volumes must be at least 47 GB."
  }
}

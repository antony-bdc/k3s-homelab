locals {
  compartment_id = coalesce(var.compartment_ocid, var.tenancy_ocid)
  shape          = "VM.Standard.A1.Flex"

  vcn_cidr          = "10.0.0.0/16" # k3s uses 10.42.0.0/16 and 10.43.0.0/16 inside the cluster
  subnet_cidr       = "10.0.1.0/24"
  server_private_ip = cidrhost(local.subnet_cidr, 10)

  # OCI Always Free: 4 Ampere OCPUs, 24 GB memory and 200 GB block storage in total.
  total_ocpus     = var.server_ocpus + var.agent_count * var.agent_ocpus
  total_memory_gb = var.server_memory_gb + var.agent_count * var.agent_memory_gb
  total_volume_gb = (1 + var.agent_count) * var.boot_volume_gb

  availability_domain = data.oci_identity_availability_domains.all.availability_domains[var.availability_domain_index].name
  image_id            = data.oci_core_images.ubuntu.images[0].id

  tags = { project = "k3s-homelab" }
}

data "oci_identity_availability_domains" "all" {
  compartment_id = var.tenancy_ocid
}

# Newest Canonical Ubuntu 24.04 build for Ampere (aarch64).
data "oci_core_images" "ubuntu" {
  compartment_id           = local.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = local.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Shared join secret: known before any node boots, so agents can join without SSH round trips.
resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

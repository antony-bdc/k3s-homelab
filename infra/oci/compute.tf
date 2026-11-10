resource "oci_core_instance" "server" {
  availability_domain = local.availability_domain
  compartment_id      = local.compartment_id
  display_name        = "k3s-server"
  shape               = local.shape
  freeform_tags       = local.tags

  shape_config {
    ocpus         = var.server_ocpus
    memory_in_gbs = var.server_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = local.image_id
    boot_volume_size_in_gbs = var.boot_volume_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.nodes.id
    assign_public_ip = true
    private_ip       = local.server_private_ip # fixed, so agents know where to join
    hostname_label   = "k3s-server"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init/server.yaml.tftpl", {
      k3s_version = var.k3s_version
      token       = random_password.k3s_token.result
      node_ip     = local.server_private_ip
      vcn_cidr    = local.vcn_cidr
    }))
  }

  lifecycle {
    # A newer image must not replace a running node on the next apply.
    ignore_changes = [source_details[0].source_id]

    precondition {
      condition     = local.total_ocpus <= 4 && local.total_memory_gb <= 24 && local.total_volume_gb <= 200
      error_message = "This layout leaves OCI Always Free (max 4 OCPUs, 24 GB memory, 200 GB storage). Reduce nodes or sizes."
    }

    precondition {
      condition     = length(data.oci_core_images.ubuntu.images) > 0
      error_message = "No Ubuntu 24.04 image for VM.Standard.A1.Flex found in this region."
    }
  }
}

resource "oci_core_instance" "agent" {
  count = var.agent_count

  availability_domain = local.availability_domain
  compartment_id      = local.compartment_id
  display_name        = "k3s-agent-${count.index + 1}"
  shape               = local.shape
  freeform_tags       = local.tags

  shape_config {
    ocpus         = var.agent_ocpus
    memory_in_gbs = var.agent_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = local.image_id
    boot_volume_size_in_gbs = var.boot_volume_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.nodes.id
    assign_public_ip = true # outbound access for the k3s installer, inbound is limited by the security list
    hostname_label   = "k3s-agent-${count.index + 1}"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init/agent.yaml.tftpl", {
      k3s_version = var.k3s_version
      token       = random_password.k3s_token.result
      server_ip   = local.server_private_ip
      vcn_cidr    = local.vcn_cidr
    }))
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }

  depends_on = [oci_core_instance.server]
}

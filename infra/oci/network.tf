resource "oci_core_vcn" "lab" {
  compartment_id = local.compartment_id
  cidr_blocks    = [local.vcn_cidr]
  display_name   = "k3s-homelab"
  dns_label      = "k3slab"
  freeform_tags  = local.tags
}

resource "oci_core_internet_gateway" "lab" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.lab.id
  display_name   = "k3s-homelab-igw"
  enabled        = true
  freeform_tags  = local.tags
}

resource "oci_core_route_table" "public" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.lab.id
  display_name   = "k3s-homelab-public"
  freeform_tags  = local.tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.lab.id
  }
}

resource "oci_core_security_list" "nodes" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.lab.id
  display_name   = "k3s-homelab-nodes"
  freeform_tags  = local.tags

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Node to node: Kubernetes API, kubelet, flannel VXLAN. Never reachable from outside the VCN.
  ingress_security_rules {
    source      = local.vcn_cidr
    protocol    = "all"
    description = "cluster traffic inside the VCN"
  }

  ingress_security_rules {
    source      = var.admin_cidr
    protocol    = "6"
    description = "SSH from the admin address only"

    tcp_options {
      min = 22
      max = 22
    }
  }

  dynamic "ingress_security_rules" {
    for_each = { http = 80, https = 443 }

    content {
      source      = "0.0.0.0/0"
      protocol    = "6"
      description = "${ingress_security_rules.key} to the Traefik ingress"

      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  # Path MTU discovery.
  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "1"

    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_subnet" "nodes" {
  compartment_id             = local.compartment_id
  vcn_id                     = oci_core_vcn.lab.id
  cidr_block                 = local.subnet_cidr
  display_name               = "k3s-homelab-nodes"
  dns_label                  = "nodes"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.nodes.id]
  prohibit_public_ip_on_vnic = false
  freeform_tags              = local.tags
}

terraform {
  required_version = ">= 1.9"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Credentials come from ~/.oci/config (created by `oci setup config`), never from this repo.
provider "oci" {
  region              = var.region
  config_file_profile = var.oci_profile
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}

# The root module passes the target CCE cluster's kubeconfig as a string.
# We persist it to a local file (0600) for the user's own kubectl use, and
# ALSO decode it inline to configure the Kubernetes / kubectl providers.
# CCE kubeconfig uses certificate-based auth, so no cloud-specific exec
# plugin for token-based authentication is required.
#
# IMPORTANT: providers are configured INLINE (host + client cert/key + CA)
# rather than via config_path. config_path is validated at plan time, but the
# kubeconfig file is only written during apply (local_file), so a config_path
# would fail `terraform plan` with "refers to an invalid path".
resource "local_file" "kubeconfig" {
  filename        = pathexpand("~/.kube/config_cce_${var.cce_cluster_name}")
  file_permission = "0600"
  content         = var.kubeconfig_raw

  # The kubeconfig content is owned by the CCE control plane; if it rotates
  # on the cloud side we must not let Terraform "fix" it back on next apply.
  lifecycle {
    ignore_changes = [content]
  }
}

locals {
  kc          = yamldecode(var.kubeconfig_raw)
  # CCE kubeconfig contains both internal (RFC1918) and external (public IP)
  # clusters. When running Terraform from outside the VPC we MUST use the
  # public endpoint, otherwise the API returns EOF.
  kc_cluster  = try(
    [for c in local.kc.clusters : c.cluster if c.name == "externalClusterTLSVerify"][0],
    [for c in local.kc.clusters : c.cluster if c.name == "externalCluster"][0],
    local.kc.clusters[0].cluster
  )
  kc_user     = local.kc.users[0].user
  kc_ca       = try(base64decode(local.kc_cluster["certificate-authority-data"]), "")
  kc_client_c = base64decode(local.kc_user["client-certificate-data"])
  kc_client_k = base64decode(local.kc_user["client-key-data"])
}

provider "kubernetes" {
  host                   = local.kc_cluster.server
  cluster_ca_certificate = local.kc_ca
  client_certificate     = local.kc_client_c
  client_key             = local.kc_client_k
}

provider "kubectl" {
  host                    = local.kc_cluster.server
  cluster_ca_certificate  = local.kc_ca
  client_certificate      = local.kc_client_c
  client_key              = local.kc_client_k
  load_config_file        = false
}

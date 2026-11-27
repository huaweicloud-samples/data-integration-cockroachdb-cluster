variable "region" {
  description = "Huawei Cloud region for deployment"
  type        = string
  default     = "cn-north-4"
}

variable "cce_cluster_name" {
  description = "Name of the target CCE cluster (existing, or created when create_cce_cluster=true)"
  type        = string
  default     = "demo"
}

variable "number_of_nodes" {
  description = "Number of CockroachDB nodes / pods to deploy"
  type        = number
  default     = 3
}

variable "create_cce_cluster" {
  description = "When true, Terraform also provisions a CCE cluster + node pool + Everest addon. When false (default), an existing CCE cluster is referenced."
  type        = bool
  default     = false
}

variable "assign_cluster_eip" {
  description = "When create_cce_cluster=true, also allocate and bind an EIP so the cluster is reachable from the internet (needed for kubectl from outside the VPC)."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for the CCE cluster. Required when create_cce_cluster=true."
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID for the CCE cluster control plane / nodes. Required when create_cce_cluster=true."
  type        = string
  default     = ""
}

variable "cce_flavor_id" {
  description = "CCE cluster flavor (control plane size)."
  type        = string
  default     = "cce.s1.small"
}

variable "cce_cluster_version" {
  description = "Kubernetes version for the CCE cluster. null = latest available."
  type        = string
  default     = null
  nullable    = true
}

variable "node_pool_flavor" {
  description = "ECS flavor for the node pool worker nodes."
  type        = string
  default     = "s6.large.2"
}

variable "node_pool_az" {
  description = "Availability zone for the node pool. Empty = '<region>a'."
  type        = string
  default     = ""
}

variable "everest_addon_version" {
  description = "Version of the Everest (CCE Container Storage) addon. Must be compatible with the cluster version."
  type        = string
  default     = "2.4.4"
}

variable "enable_locality" {
  description = "Inject CockroachDB --locality hints from the Huawei Cloud metadata service."
  type        = bool
  default     = true
}

variable "tls_enabled" {
  description = "Enable TLS for CockroachDB. Requires cert-manager to be pre-installed when true. Default false for quick verification."
  type        = bool
  default     = false
}

variable "node_password" {
  description = "Password for the CCE node pool worker nodes. Required (or node_key_pair) when create_cce_cluster=true."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = !var.create_cce_cluster || var.node_password != "" || var.node_key_pair != ""
    error_message = "When create_cce_cluster=true you must set either node_password or node_key_pair."
  }
}

variable "node_key_pair" {
  description = "Keypair name for the CCE node pool. Provide EITHER node_password OR node_key_pair when create_cce_cluster=true."
  type        = string
  default     = ""
}

variable "create_vpc" {
  description = "When true (default), also create a VPC + subnet for the CCE cluster (used when the account has no VPC yet). Set false to reference existing vpc_id/subnet_id."
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR for the bootstrap VPC (used when create_vpc=true)."
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR for the bootstrap subnet (used when create_vpc=true). Must be a subset of vpc_cidr."
  type        = string
  default     = "192.168.0.0/24"
}

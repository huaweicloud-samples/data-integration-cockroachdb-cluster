variable "deploy_client" {
  description = "Select true to deploy the secure client Pod, else select false"
  type        = bool
  default     = true
}

variable "tls_enabled" {
  description = "Enable TLS for CockroachDB. Requires cert-manager to be pre-installed when true."
  type        = bool
  default     = false
}

variable "crd_manifest_file" {
  description = "YAML manifests file to create custom resource."
  type        = string
  default     = ""
}

variable "certificate_manifest_directory" {
  description = "Directory containing cert-manager Certificate/Issuer manifests."
  type        = string
  default     = ""
}

variable "database_manifest_file" {
  description = "YAML manifest file to create a crdb cluster resource."
  type        = string
  default     = ""
}

variable "elb_manifest_file" {
  description = "YAML manifest file to create a LoadBalancer (ELB) Service."
  type        = string
  default     = ""
}

variable "client_manifest_file" {
  description = "YAML manifest file to create cockroachdb client pod."
  type        = string
  default     = ""
}

variable "operator_manifest_directory" {
  description = "Directory containing the CockroachDB operator manifests."
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Namespace name for resource creation"
  type        = string
  default     = "staging"
}

variable "region" {
  description = "Huawei Cloud region for the cluster (used in CockroachDB locality hints)"
  type        = string
  default     = "cn-north-4"
}

variable "number_of_nodes" {
  description = "Describes the minimum number of nodes required by cluster"
  type        = number
  default     = 3
}

variable "cpu_limit" {
  description = "Describes the sum of the CPU limit for all the Containers in the Pod"
  type        = string
  default     = "1"
}

variable "cpu_requests" {
  description = "Describes the sum of the CPU requests for all the Containers in the Pod"
  type        = string
  default     = "560m"
}

variable "memory_limit" {
  description = "Describes the memory limit of a container"
  type        = string
  default     = "3Gi"
}

variable "memory_request" {
  description = "Describes the memory requests of a container"
  type        = string
  default     = "2Gi"
}

variable "max_sql_memory" {
  description = "Describes the maximum in-memory storage capacity available to store temporary data for SQL queries"
  type        = string
  default     = "18%"
}

variable "max_disk_temp_storage" {
  description = "Describes the maximum on-disk storage capacity available to store temporary data for SQL queries"
  type        = string
  default     = "32GiB"
}

variable "persistent_volume_size" {
  description = "Describes the storage capacity of each volume"
  type        = string
  default     = "60Gi"
}

variable "crdb_version" {
  description = "Describes the version details of cockroachdb"
  type        = string
  default     = "v22.2.2"
}

variable "additional_tags" {
  description = "Additional tags applied to the ELB resource"
  type        = map(any)
  default     = {}
}

variable "node_certificate_file" {
  description = "YAML file for Certificate resource"
  type        = string
  default     = ""
}

variable "cce_cluster_name" {
  description = "Name of the CCE cluster the kubeconfig belongs to (used for the local kubeconfig file name)"
  type        = string
  default     = ""
}

variable "kubeconfig_raw" {
  description = "Raw kubeconfig of the target CCE cluster (from huaweicloud_cce_cluster). Written locally and used by the kubernetes/kubectl providers."
  type        = string
  sensitive   = true
}

variable "create_everest_gpssd_storage_class" {
  description = "When set to true, creates the everest-gpssd StorageClass backed by Huawei Cloud Everest CSI (EVS GPSSD)"
  type        = bool
  default     = true
}

variable "enable_locality" {
  description = "When true, inject CockroachDB --locality hints read from the Huawei Cloud metadata service. Set false if pods cannot reach 169.254.169.254."
  type        = bool
  default     = true
}

variable "serviceaccount" {
  description = "ServiceAccount used by the secure client pod"
  type        = string
  default     = "cockroachdb-sa"
}

variable "cluster_settings_file" {
  description = "Custom file for Cluster settings"
  type        = string
  default     = ""
}

variable "sql_stats_persisted_rows_max" {
  description = "Describes maximum number of rows of statement and transaction activity that will be persisted in the system tables"
  type        = string
  default     = "2000"
}

variable "cluster_organization" {
  description = "Describes the org name"
  type        = string
  default     = "apg_data_delivery"
}

variable "sql_log_slow_query_latency_threshold" {
  description = "Describes the threshold to trigger anomaly detection and identification"
  type        = string
  default     = "10s"
}

variable "server_time_until_store_dead" {
  description = "Describes the time after which a store is considered dead when no new information"
  type        = string
  default     = "10m0s"
}

variable "admission_kv_enabled" {
  description = "When true, work performed by the KV layer is subject to admission control"
  type        = string
  default     = "false"
}

variable "admission_sql_kv_response_enabled" {
  description = "when true, work performed by the SQL layer when receiving a KV response is subject to admission control"
  type        = string
  default     = "false"
}

variable "admission_sql_sql_response_enabled" {
  description = "when true, work performed by the SQL layer when receiving a DistSQL response is subject to admission control"
  type        = string
  default     = "false"
}

variable "kv_snapshot_rebalance_max_rate" {
  description = "Describes the rate limit (bytes/sec) to use for rebalance and upreplication snapshots"
  type        = string
  default     = "64 MiB"
}

variable "kv_snapshot_recovery_max_rate" {
  description = "Describes the rate limit (bytes/sec) to use for recovery"
  type        = string
  default     = "64 MiB"
}

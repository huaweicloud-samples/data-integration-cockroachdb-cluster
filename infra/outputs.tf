output "crdb_namespace" {
  description = "Namespace where CockroachDB is deployed"
  value       = module.crdb.namespace
}

output "cce_kubeconfig_path" {
  description = "Local path of the CCE kubeconfig written for the kubernetes/kubectl providers"
  value       = module.crdb.kubeconfig_path
}

output "cce_cluster_id" {
  description = "ID of the CCE cluster created by this configuration (empty when referencing an existing cluster)"
  value       = var.create_cce_cluster ? huaweicloud_cce_cluster.created[0].id : ""
}

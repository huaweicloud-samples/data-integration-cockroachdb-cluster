output "namespace" {
  description = "Namespace where CockroachDB is deployed"
  value       = kubernetes_namespace.namespace.metadata[0].name
}

output "everest_gpssd_storage_class_name" {
  description = "Name of the everest-gpssd StorageClass created for CockroachDB PVCs"
  value       = var.create_everest_gpssd_storage_class ? "everest-gpssd" : "everest-gpssd (assumed to already exist)"
}

output "kubeconfig_path" {
  description = "Local path of the CCE kubeconfig used by this module"
  value       = local_file.kubeconfig.filename
}

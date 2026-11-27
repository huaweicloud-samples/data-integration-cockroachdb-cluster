# Render the CockroachDB cluster settings SQL from the cmd.txt template.
locals {
  cluster_settings_rendered = templatefile(local.cluster_settings_file, {
    sql_stats_persisted_rows_max         = var.sql_stats_persisted_rows_max
    cluster_organization                 = var.cluster_organization
    sql_log_slow_query_latency_threshold = var.sql_log_slow_query_latency_threshold
    server_time_until_store_dead         = var.server_time_until_store_dead
    admission_kv_enabled                 = var.admission_kv_enabled
    admission_sql_kv_response_enabled    = var.admission_sql_kv_response_enabled
    admission_sql_sql_response_enabled   = var.admission_sql_sql_response_enabled
    kv_snapshot_rebalance_max_rate       = var.kv_snapshot_rebalance_max_rate
    kv_snapshot_recovery_max_rate        = var.kv_snapshot_recovery_max_rate
  })
}

resource "local_file" "cluster_settings" {
  filename        = pathexpand("~/cluster_settings.txt")
  file_permission = "0600"
  content         = local.cluster_settings_rendered
}

# Apply the cluster settings once the database is up. Requires the `kubectl`
# CLI to be available on the machine running Terraform.
# When TLS is disabled we skip this step; the default settings are sufficient
# for verification and the secure client pod is not deployed.
resource "null_resource" "cluster_settings" {
  count = var.tls_enabled ? 1 : 0

  depends_on = [
    kubectl_manifest.database,
    time_sleep.database_wait,
    local_file.cluster_settings,
    kubectl_manifest.client
  ]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=\"${local_file.kubeconfig.filename}\" exec -it cockroachdb-client-secure --namespace=${local.namespace} -- ./cockroach sql --certs-dir=/cockroach/cockroach-certs --host=cockroachdb-public.${local.namespace} < ${local_file.cluster_settings.filename}"
  }

  triggers = {
    everytime = timestamp()
  }
}

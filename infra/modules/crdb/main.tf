# ---------------------------------------------------------------------------
# Namespace
# ---------------------------------------------------------------------------
resource "kubernetes_namespace" "namespace" {
  metadata {
    name = local.namespace
    annotations = {
      name = local.namespace
    }
  }

  lifecycle {
    # CCE / system controllers may add annotations at runtime; do not let
    # Terraform treat those as drift and "fix" them back on every apply.
    ignore_changes = [metadata[0].annotations]
  }
}

# ---------------------------------------------------------------------------
# everest-gpssd StorageClass backed by Huawei Cloud Everest CSI (EVS GPSSD)
# ---------------------------------------------------------------------------
resource "kubernetes_storage_class" "everest_gpssd" {
  count = var.create_everest_gpssd_storage_class ? 1 : 0

  metadata {
    name = "everest-gpssd"
  }

  storage_provisioner = "everest-csi-provisioner"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    "csi.storage.k8s.io/csi-driver-name" = "disk.csi.everest.io"
    "csi.storage.k8s.io/fstype"          = "ext4"
    "everest.io/disk-volume-type"        = "GPSSD" # 通用型 SSD
    "everest.io/passthrough"             = "true"
  }
}

# ---------------------------------------------------------------------------
# Certificates (cert-manager must already be installed on the CCE cluster)
# ---------------------------------------------------------------------------
locals {
  certificate_manifests = {
    for f in fileset(local.certificate_manifest_directory, "*.yaml") :
    f => templatefile("${local.certificate_manifest_directory}/${f}", {})
  }
}

resource "kubectl_manifest" "cert" {
  for_each           = var.tls_enabled ? local.certificate_manifests : {}
  yaml_body          = each.value
  override_namespace = kubernetes_namespace.namespace.metadata[0].name
}

resource "kubectl_manifest" "node_certificate" {
  count = var.tls_enabled ? 1 : 0
  yaml_body = templatefile(local.node_certificate_file, {
    namespace    = local.namespace
    crdb_cluster = local.crdb_cluster
  })
  override_namespace = kubernetes_namespace.namespace.metadata[0].name
  depends_on = [
    kubectl_manifest.cert
  ]
}

# ---------------------------------------------------------------------------
# CockroachDB CustomResourceDefinition
# ---------------------------------------------------------------------------
resource "kubectl_manifest" "crd" {
  yaml_body = file(local.crd_manifest_file)
}

# ---------------------------------------------------------------------------
# CockroachDB operator
# ---------------------------------------------------------------------------
locals {
  operator_manifests = {
    for f in fileset(local.operator_manifest_directory, "*.yaml") :
    f => templatefile("${local.operator_manifest_directory}/${f}", {
      operator_namespace = local.operator_namespace
      namespace_to_watch = kubernetes_namespace.namespace.metadata[0].name
    })
  }
}

resource "kubectl_manifest" "operator" {
  for_each  = local.operator_manifests
  yaml_body = each.value
}

resource "time_sleep" "operator_wait" {
  depends_on      = [kubectl_manifest.operator]
  create_duration = "10s"
}

# ---------------------------------------------------------------------------
# CockroachDB cluster (CrdbCluster CR)
# ---------------------------------------------------------------------------
resource "kubectl_manifest" "database" {
  yaml_body = templatefile(local.database_manifest_file, {
    number_of_nodes        = var.number_of_nodes
    cpu_requests           = var.cpu_requests
    memory_request         = var.memory_request
    cpu_limit              = var.cpu_limit
    memory_limit           = var.memory_limit
    persistent_volume_size = var.persistent_volume_size
    max_sql_memory         = var.max_sql_memory
    region                 = var.region
    max_disk_temp_storage  = var.max_disk_temp_storage
    storageClassName       = "everest-gpssd"
    enable_locality        = var.enable_locality
  })
  override_namespace = kubernetes_namespace.namespace.metadata[0].name

  depends_on = [
    kubectl_manifest.operator,
    kubectl_manifest.cert,
    kubectl_manifest.crd,
    time_sleep.operator_wait,
    kubernetes_storage_class.everest_gpssd
  ]
}

resource "time_sleep" "database_wait" {
  depends_on      = [kubectl_manifest.database]
  create_duration = "15s"
}

# ---------------------------------------------------------------------------
# Secure client pod
# ---------------------------------------------------------------------------
resource "kubectl_manifest" "client" {
  count = var.tls_enabled && var.deploy_client ? 1 : 0

  yaml_body = templatefile(local.client_manifest_file, {
    serviceaccount = local.serviceaccount
  })
  override_namespace = kubernetes_namespace.namespace.metadata[0].name
  depends_on = [
    kubectl_manifest.database,
    kubectl_manifest.cert,
    time_sleep.database_wait
  ]
}

# ---------------------------------------------------------------------------
# LoadBalancer Service -> Huawei Cloud ELB
# ---------------------------------------------------------------------------
resource "kubectl_manifest" "elb" {
  yaml_body = templatefile(local.elb_manifest_file, {
    additional_tags   = join(",", setunion(local.additional_tags, ["env=${local.namespace}"]))
    crdb_cluster      = local.crdb_cluster
    availability_zone = "${var.region}a"
  })
  override_namespace = kubernetes_namespace.namespace.metadata[0].name
  depends_on = [
    kubectl_manifest.database,
    time_sleep.database_wait,
    kubectl_manifest.cert
  ]
}

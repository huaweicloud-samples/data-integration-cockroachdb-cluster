locals {
  crd_manifest_file              = var.crd_manifest_file == "" ? "${path.module}/manifest/crds.yaml" : var.crd_manifest_file
  database_manifest_file         = var.database_manifest_file == "" ? "${path.module}/manifest/database.yaml" : var.database_manifest_file
  elb_manifest_file              = var.elb_manifest_file == "" ? "${path.module}/manifest/elb.yaml" : var.elb_manifest_file
  client_manifest_file           = var.client_manifest_file == "" ? "${path.module}/manifest/client-secure-operator.yaml" : var.client_manifest_file
  namespace                      = var.namespace
  crdb_cluster                   = "cockroachdb"
  serviceaccount                 = var.serviceaccount
  operator_namespace             = "cockroach-operator-system"
  operator_manifest_directory    = var.operator_manifest_directory == "" ? "${path.module}/manifest/operator" : var.operator_manifest_directory
  certificate_manifest_directory = var.certificate_manifest_directory == "" ? "${path.module}/manifest/certificate" : var.certificate_manifest_directory
  node_certificate_file          = var.node_certificate_file == "" ? "${path.module}/manifest/node_certificate.yaml" : var.node_certificate_file
  cluster_settings_file          = var.cluster_settings_file == "" ? "${path.module}/manifest/cmd.txt" : var.cluster_settings_file

  # Render additional_tags as a comma separated "key=value" list (used by the ELB tag annotation)
  additional_tags = formatlist("%s=%s", keys(var.additional_tags), values(var.additional_tags))
}

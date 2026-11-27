terraform {
  required_version = ">= 1.5"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.70"
    }
  }
}

provider "huaweicloud" {
  region = var.region
  # AK/SK 从环境变量读取，绝不硬编码：
  #   export HW_ACCESS_KEY="<HW_ACCESS_KEY>"
  #   export HW_SECRET_KEY="<HW_SECRET_KEY>"
  # 临时凭证再加 export HW_SECURITY_TOKEN="<TOKEN>"
}

# ---------------------------------------------------------------------------
# 获取目标 CCE 集群的 kubeconfig
# ---------------------------------------------------------------------------
# 默认（create_cce_cluster=false）：引用已存在的 CCE 集群。
data "huaweicloud_cce_cluster" "existing" {
  count = var.create_cce_cluster ? 0 : 1
  name  = var.cce_cluster_name
}

locals {
  # 二选一：已存在集群（data source）或由本仓库创建的集群（resource）
  kubeconfig_raw = var.create_cce_cluster ? huaweicloud_cce_cluster.created[0].kube_config_raw : data.huaweicloud_cce_cluster.existing[0].kube_config_raw
}

module "common-tags" {
  source = "./modules/common-tags"
}

# ---------------------------------------------------------------------------
# CockroachDB on CCE
# ---------------------------------------------------------------------------
module "crdb" {
  source = "./modules/crdb"

  namespace        = "prod"
  region           = var.region
  cce_cluster_name = var.cce_cluster_name
  kubeconfig_raw   = local.kubeconfig_raw

  number_of_nodes        = var.number_of_nodes
  cpu_limit              = "500m"
  cpu_requests           = "250m"
  memory_limit           = "1Gi"
  memory_request         = "512Mi"
  crdb_version           = "v22.2.2"
  max_sql_memory         = "18%"
  max_disk_temp_storage  = "32GiB"
  persistent_volume_size = "60Gi"

  additional_tags         = module.common-tags.tags
  create_everest_gpssd_storage_class = true
  enable_locality         = var.enable_locality
  tls_enabled             = var.tls_enabled
}

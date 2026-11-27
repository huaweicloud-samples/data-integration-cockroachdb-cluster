# ============================================================================
# 可选：一键拉起 CCE 集群 + 节点池 + Everest 存储插件
# ----------------------------------------------------------------------------
# 默认关闭（create_cce_cluster=false）。默认引用一个已存在的 CCE 集群；
# 将 create_cce_cluster 设为 true 可让本仓库完全自包含地创建一套可运行环境。
# 开启前请通过 terraform plan 预览并确认将要创建的资源。
# ============================================================================

# 集群公网访问 EIP（可选）
resource "huaweicloud_vpc_eip" "cce" {
  count = var.create_cce_cluster && var.assign_cluster_eip ? 1 : 0

  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.cce_cluster_name}-cce-bandwidth"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# ---------------------------------------------------------------------------
# 网络地基：账号无 VPC 时由本仓库自建（明确不含 NAT 网关）
# ---------------------------------------------------------------------------
resource "huaweicloud_vpc" "bootstrap" {
  count = var.create_cce_cluster && var.create_vpc ? 1 : 0
  name  = "${var.cce_cluster_name}-vpc"
  cidr  = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "bootstrap" {
  count           = var.create_cce_cluster && var.create_vpc ? 1 : 0
  name            = "${var.cce_cluster_name}-subnet"
  vpc_id          = huaweicloud_vpc.bootstrap[0].id
  cidr            = var.subnet_cidr
  gateway_ip      = cidrhost(var.subnet_cidr, 1)
  availability_zone = coalesce(var.node_pool_az, "${var.region}a")
  description     = "Bootstrap subnet for CCE nodes. No NAT gateway; outbound arranged separately (SWR mirror / node EIP) per deployment decision."
}

resource "huaweicloud_cce_cluster" "created" {
  count                  = var.create_cce_cluster ? 1 : 0
  name                   = var.cce_cluster_name
  flavor_id              = var.cce_flavor_id
  vpc_id                 = var.create_vpc ? huaweicloud_vpc.bootstrap[0].id : var.vpc_id
  subnet_id              = var.create_vpc ? huaweicloud_vpc_subnet.bootstrap[0].id : var.subnet_id
  container_network_type = "vpc-router"
  cluster_version        = var.cce_cluster_version
  eip                    = var.create_cce_cluster && var.assign_cluster_eip ? huaweicloud_vpc_eip.cce[0].address : null
}

resource "huaweicloud_cce_node_pool" "created" {
  count         = var.create_cce_cluster ? 1 : 0
  cluster_id    = huaweicloud_cce_cluster.created[0].id
  name          = "${var.cce_cluster_name}-nodepool"
  flavor_id     = var.node_pool_flavor
  type          = "vm"
  runtime       = "containerd"
  os            = "Huawei Cloud EulerOS 2.0"
  initial_node_count = var.number_of_nodes
  min_node_count = 1
  max_node_count = var.number_of_nodes * 2
  scall_enable  = true
  availability_zone = coalesce(var.node_pool_az, "${var.region}a")
  subnet_id     = var.create_vpc ? huaweicloud_vpc_subnet.bootstrap[0].id : var.subnet_id
  password      = var.node_password != "" ? var.node_password : null
  key_pair      = var.node_key_pair != "" ? var.node_key_pair : null

  # CockroachDB database.yaml requires nodes labeled node=cockroachdb.
  labels = {
    "node" = "cockroachdb"
  }

  root_volume {
    size       = 40
    volumetype = "GPSSD"
  }
  data_volumes {
    size       = 100
    volumetype = "GPSSD"
  }
}

# Everest（CCE 容器存储）插件：CCE 创建时已自动预装 Everest CSI，因此不再由
# Terraform 重复管理。everest-gpssd StorageClass（modules/crdb/main.tf）直接引用现有的
# everest-csi-provisioner。

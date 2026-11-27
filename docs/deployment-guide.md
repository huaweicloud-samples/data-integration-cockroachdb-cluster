# 部署指导书：在 CCE 上部署 CockroachDB

> 基于 Terraform + Huawei Cloud 的部署步骤。

## 1. 前置条件

- 已开通华为云账号，具备 `cn-north-4`（或目标 Region）权限。
- 本地已安装：`terraform >= 1.5`、`kubectl`、可访问目标 CCE 集群的机器。
- 目标 CCE 集群（**默认引用已有集群**）已存在，且已安装 **cert-manager**（helm 安装）。
- cert-manager 安装示例：`helm repo add jetstack https://charts.jetstack.io && helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true`
- Everest 容器存储插件：CCE 集群默认自带；若用 `create_cce_cluster=true` 自动创建集群，本实践会自动安装 Everest（`everest` addon）。

## 2. 配置凭据（请勿硬编码）

凭据一律通过环境变量注入，绝不以明文写入任何 `.tf` 文件：

```bash
export HW_ACCESS_KEY="<HW_ACCESS_KEY>"
export HW_SECRET_KEY="<HW_SECRET_KEY>"
# 临时凭证再加：
# export HW_SECURITY_TOKEN="<TOKEN>"
```

> 请将认证信息只通过环境变量注入，不要写入代码或配置文件；下文示例中的 `<HW_ACCESS_KEY>` 等均为占位符，请替换为你自己的值。

## 3. 方式一：引用已有 CCE 集群（默认）

```bash
cd infra
terraform init
terraform plan \
-var="region=cn-north-4" \
-var="cce_cluster_name=<你的CCE集群名>"
terraform apply \
-var="region=cn-north-4" \
-var="cce_cluster_name=<你的CCE集群名>"
```

要点：
- `create_cce_cluster` 默认 `false`，仅引用已有集群，不新建任何云资源。
- 新建资源仅为集群内的 K8s 对象（命名空间、StorageClass、证书、Operator、CrdbCluster、Service），不产生独立的云资源。

## 4. 方式二：一键创建 CCE 集群（可选，自包含）

设置 `create_cce_cluster=true`，并传入 VPC / 子网与节点登录方式：

```bash
terraform apply \
-var="region=cn-north-4" \
-var="cce_cluster_name=crdb-demo" \
-var="create_cce_cluster=true" \
-var="vpc_id=<vpc-id>" \
-var="subnet_id=<subnet-id>" \
-var="node_password=<强密码>" \
-var="number_of_nodes=3"
```

> ⚠️ 该模式会创建 CCE 控制面、节点池（ECS）、EIP、ELB 等云资源。apply 前请执行 `terraform plan` 预览并确认将要创建的资源。

## 5. 验证部署

```bash
# 1) 查看 CockroachDB Pod 状态
kubectl --kubeconfig ~/.kube/config_cce_<集群名> -n prod get pods

# 2) 查看 ELB 分配的外部 IP
kubectl --kubeconfig ~/.kube/config_cce_<集群名> -n prod get svc cockroach-elb

# 3) 通过安全客户端连接（SQL）
kubectl --kubeconfig ~/.kube/config_cce_<集群名> -n prod exec -it cockroachdb-client-secure -- \
./cockroach sql --certs-dir=/cockroach/cockroach-certs --host=cockroachdb-public.prod

# 4) 集群健康
cockroach sql> SELECT * FROM crdb_internal.node_runtime_info;
```

## 6. 常见调整

| 需求 | 操作 |
|---|---|
| 改为私网 ELB | 编辑 `infra/modules/crdb/manifest/elb.yaml`，将 `autocreate` 的 `"type":"public"` 改为 `"type":"inner"`，并删除带宽/EIP 字段 |
| 关闭 locality | 设 `enable_locality=false` |
| 调整节点数 | 改 `number_of_nodes`（注意 StatefulSet 需逐级滚动，建议奇数 3/5/7） |
| 改用 SWR 镜像 | 将 `database.yaml` 中 `image.name` 改为 SWR 地址，并重装 Operator 镜像 |
| 自定义标签 | 修改根模块 `module "common-tags"` 输出的 tags 映射 |

## 7. 清理

```bash
terraform destroy # 方式二会一并销毁 CCE 集群 / 节点池 / EIP / ELB
```

> 调试完成后务必 `destroy` 并到控制台 API 直查 ECS / EVS / ELB / EIP 是否有 `status=available` 孤儿资源残留（尤其 EVS 云硬盘，ECS 删除不必然连带删盘）。

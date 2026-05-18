# K8s 实验环境

## 集群信息
- k3s v1.35.4+k3s1, 3 节点 (k3s-master, k3s-worker1, k3s-worker2)
- CNI: Calico v3.28.0 VXLAN, CIDR 10.42.0.0/16
- 容器运行时: containerd://2.2.3-k3s1

## 目录结构


## 实验清单

| 实验 | 内容 | 核心资源 | 状态 |
|------|------|---------|------|
| 实验一 | Calico NetworkPolicy Ingress 三层隔离 | 6 Pods + 6 NPs (deny-all, allow-web-to-api, allow-api-to-db) | ✅ |
| 实验二 | Ingress Controller + Egress 出站控制 | nginx-ingress, deny-db-egress, allow-api-egress-dns | ✅ |
| 实验三 | SDN 服务上 K8s | Ryu StatefulSet + Mininet Pod, OpenFlow 握手 | ✅ |
| 实验四 | Prometheus + Grafana 监控 | kube-prometheus-stack (Helm chart 85.1.2) | ✅ |
| 实验五 | Calico VXLAN vs IPIP 对比 | iperf3 跨节点吞吐量 + 抓包分析 | ✅ |
| 中间件 | Redis Cluster + MySQL | 3主3从 Redis (hostname 自愈) + MySQL 8.0 | ✅ |

## 关键踩坑
1. **镜像分发**: daocloud 不稳定, quay.io 代理 403, registry.k8s.io 可用; 用 133 Docker VPN 拉 + base64 pipe 传节点
2. **NetworkPolicy 隐式拒绝**: 一旦有策略选中 Pod, 该 Pod 只接受明确允许的流量; Egress 策略会锁死源端出站
3. **Redis Cluster 自愈**: 用 --cluster-announce-hostname + DNS 名建集群, Pod 重启 IP 变也不怕
4. **YAML 缩进**: vim 粘贴易被终端自动缩进破坏, 用 cat pipe 或 base64 传输
5. **CoreDNS Pod DNS 记录丢失**: 个别 Pod NXDOMAIN 时, 删 Pod 让 StatefulSet 重建即可恢复


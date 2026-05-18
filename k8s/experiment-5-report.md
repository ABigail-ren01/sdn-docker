# 实验五: Calico VXLAN vs IPIP Overlay 对比

## 测试环境
- 集群: k3s v1.35.4+k3s1, 3 节点 (master + worker1 + worker2)
- CNI: Calico v3.28.0 (tigera-operator)
- 测试工具: iperf3 (networkstatic/iperf3:latest)
- 测试 Pod: iperf-server (master) ↔ iperf-client (worker2), 跨节点 overlay 流量

## VXLAN 模式

### 配置
- vxlanMode: Always, ipipMode: Never
- VNI: 4096
- 封装: Eth + IP + UDP(4789) + VXLAN(8B) + Inner Eth + Inner IP + Payload
- 头开销: 50 bytes

### 抓包 (tcpdump -i ens3 udp port 4789)


### 吞吐量 (iperf3 -t 30)
- 平均: 1.11 Gbits/sec
- 重传: 241 次/30秒
- 波动范围: 718 Mbits/sec ~ 1.24 Gbits/sec

## IPIP 模式

### 配置
- vxlanMode: Never, ipipMode: Always  
- tunl0 MTU: 1480
- 封装: IP(proto 4) + Inner IP + Payload
- 头开销: 20 bytes

### 抓包 (tcpdump -i ens3 ip proto 4)


### 吞吐量 (iperf3 -t 5)
- 平均: 1.19 Gbits/sec
- 重传: 123 次/5秒
- 波动范围: 879 Mbits/sec ~ 1.35 Gbits/sec

## 对比总结

| 维度 | VXLAN | IPIP |
|------|-------|------|
| 封装协议 | UDP 4789 | IP proto 4 |
| 头开销 | 50 bytes | 20 bytes |
| MTU | 1450 | 1480 |
| 平均吞吐量 | 1.11 Gbits/sec | 1.19 Gbits/sec |
| 多租户支持 | 支持 (VNI 24-bit, 16M 隔离域) | 不支持 |
| 交换机兼容性 | 标准 UDP, 可被哈希 | 需识别 IP proto 4 |
| 适用场景 | 大规模多租户, 跨数据中心 | 小规模同子网 overlay |

## 结论
IPIP 因头开销少 30 bytes, 吞吐量略高约 7%。但 VXLAN 凭借 VNI 提供多租户隔离能力,
适合生产级大规模部署。本实验环境规模小, 两种模式性能差异不显著,
默认 VXLAN 模式完全满足需求。


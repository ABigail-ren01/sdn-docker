# SDN Docker - Mininet + Ryu Dual-Container

## Architecture

```
+--------------------------+       +--------------------------+
|     Ryu Container        |       |     Mininet Container    |
|  192.168.100.10          |       |  192.168.100.20          |
|                          |       |                          |
|  Ubuntu 22.04            |       |  Ubuntu 22.04            |
|  Python 3.10             | 6633  |  Python 3.10             |
|  Ryu 4.34                |<------|  Mininet 2.3.0           |
|  (OpenFlow Controller)   | OpenFlow |  OVS 2.17.9            |
+--------------------------+       |  (--privileged)          |
                                   +--------------------------+
            |                                |
            +--------------------------------+
                     sdn-net (custom bridge)
                    192.168.100.0/24
                            |
                     Docker Host
```

## Quick Start

### 1. Create custom network
```bash
docker network create \
  --driver bridge \
  --subnet=192.168.100.0/24 \
  --gateway=192.168.100.1 \
  sdn-net
```

### 2. Build images
```bash
docker build -t ryu-img -f Dockerfile.ryu .
docker build -t mn-img -f Dockerfile.mininet .
```

### 3. Run containers
```bash
# Start Ryu controller
docker run -d --name ryu --network sdn-net --ip 192.168.100.10 \
  -p 6633:6633 ryu-img

# Start Mininet
docker run -d --name mn --network sdn-net --ip 192.168.100.20 \
  --privileged mn-img
```

### 4. Launch topology
```bash
docker exec -it mn bash
mn --topo single,3 --switch ovsk \
   --controller remote,ip=192.168.100.10,port=6633 --mac
mininet> pingall
```

## Pre-built Images

Pull from GitHub Container Registry:
```bash
docker pull ghcr.io/abigail-ren01/sdn-ryu:latest
docker pull ghcr.io/abigail-ren01/sdn-mn:latest
```

## Key Design Decisions

| Issue | Solution |
|-------|----------|
| Python 3.12 incompatibility | Ubuntu 22.04 with Python 3.10 inside containers |
| Container IP changes on restart | Custom bridge + static IP |
| Ryu/eventlet version conflict | Patch `ALREADY_HANDLED` into eventlet.wsgi |
| Missing tools in minimal image | apt install all deps in Dockerfile |
| OVS not auto-starting in Docker | entrypoint.sh auto-starts OVS services |

## Files

- `Dockerfile.ryu` - Ryu SDN controller image
- `Dockerfile.mininet` - Mininet topology emulator image
- `entrypoint.sh` - OVS auto-start script for Mininet container

## Troubleshooting

故障症状（你实际会看到的报错）	根因分析	检查命令	一键修复命令	
ImportError: cannot import name 'ALREADY_HANDLED' from 'eventlet.wsgi'	Ryu 4.34 与 eventlet 0.34 + 版本不兼容，ALREADY_HANDLED常量已被官方移除	pip3 show eventlet	pip3 install --force-reinstall eventlet==0.33.2	
Cannot find required executable mnexec	仅安装了 Mininet 的 Python 代码，未编译安装 C 语言核心工具	which mnexec	cd /opt/mininet && make install	
Cannot find required executable ifconfig	Ubuntu 22.04 精简镜像默认移除了传统网络工具包	which ifconfig	apt update && apt install -y net-tools	
bash: ip: command not found	未安装现代 Linux 网络工具包	which ip	apt update && apt install -y iproute2	
bash: ping: command not found	未安装基础网络诊断工具包	which ping	apt update && apt install -y iputils-ping	
ovs-vsctl: unix:/var/run/openvswitch/db.sock: database connection failed	OVS 数据库服务ovsdb-server未启动	service openvswitch-switch status	service openvswitch-switch start	
Unable to contact the remote controller at 192.168.100.10:6633	控制器未启动 / 端口未监听 / 网络不通	`netstat -tlnp	grep 6633`	1. 重启 Ryu 容器：docker restart ryu2. 验证网络连通性：docker exec mn ping -c 3 192.168.100.103. 检查防火墙是否开放 6633 端口
*** Error setting resource limits. Mininet's performance may be affected.	Docker 容器默认没有修改系统文件描述符限制的权限	-	启动容器时添加参数：--ulimit nofile=1024:1024	
mininet> pingall 100% 丢包	控制器未下发流表 / OVS 未成功连接控制器	ovs-ofctl dump-flows s1	1. 查看 Ryu 日志：docker logs ryu --tail 202. 确认 Mininet 连接的 IP 和端口正确3. 重启 Mininet 拓扑	
Error creating interface pair (h1-eth0,s1-eth1)	容器未开启特权模式，无法创建内核虚拟网络设备	-	启动容器时添加参数：--privileged	
OCI runtime exec failed: executable file not found in $PATH	容器内缺少对应的可执行文件	which [命令名]	在容器内安装对应的软件包	

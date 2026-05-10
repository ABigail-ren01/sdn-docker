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

| Symptom | Check / Fix |
|---------|-------------|
| `ImportError: cannot import name 'ALREADY_HANDLED'` | `pip3 install --force-reinstall eventlet==0.33.2` |
| `Cannot find required executable mnexec` | `cd /opt/mininet && make install` |
| `Cannot find required executable ifconfig` | `apt update && apt install -y net-tools` |
| `bash: ip: command not found` | `apt update && apt install -y iproute2` |
| `bash: ping: command not found` | `apt update && apt install -y iputils-ping` |
| `ovs-vsctl: database connection failed` | `service openvswitch-switch start` |
| `Unable to contact remote controller` | 1. `docker restart ryu`<br>2. `docker exec mn ping 192.168.100.10` |
| `Error setting resource limits` | Add `--ulimit nofile=1024:1024` to docker run |
| `mininet> pingall` 100% packet loss | 1. `docker logs ryu --tail 20`<br>2. `ovs-ofctl dump-flows s1` |
| `Error creating interface pair` | Add `--privileged` to docker run |
| `OCI runtime exec failed: executable not found` | Install missing package inside container |
| OpenFlow handshake fails | Verify Ryu listens on `0.0.0.0:6633` not `127.0.0.1` |
OCI runtime exec failed: executable file not found in $PATH	容器内缺少对应的可执行文件	which [命令名]	在容器内安装对应的软件包	

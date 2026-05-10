#!/bin/bash
set -e

if [ ! -f /etc/openvswitch/conf.db ]; then
    ovsdb-tool create /etc/openvswitch/conf.db /usr/share/openvswitch/vswitch.ovsschema
fi

mkdir -p /var/run/openvswitch

ovsdb-server /etc/openvswitch/conf.db \
    --remote=punix:/var/run/openvswitch/db.sock \
    --pidfile --detach 2>/dev/null || true

sleep 1
ovs-vsctl --no-wait init 2>/dev/null || true

ovs-vswitchd --pidfile --detach 2>/dev/null || true

sleep 1
echo "OVS started. Container ready."

exec "$@"

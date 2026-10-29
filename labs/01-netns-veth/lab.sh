#!/usr/bin/env bash
# Two namespaces on a Linux bridge, with NAT out to the host's uplink.
set -euo pipefail

BR=br0
SUBNET=10.0.0.0/24
GW=10.0.0.1

up() {
  ip link add "$BR" type bridge
  ip addr add "$GW/24" dev "$BR"
  ip link set "$BR" up

  local i=2
  for ns in red blue; do
    ip netns add "$ns"
    ip link add "veth-$ns" type veth peer name eth0 netns "$ns"
    ip link set "veth-$ns" master "$BR" up
    ip -n "$ns" addr add "10.0.0.$i/24" dev eth0
    ip -n "$ns" link set eth0 up
    ip -n "$ns" link set lo up
    ip -n "$ns" route add default via "$GW"
    i=$((i + 1))
  done

  sysctl -qw net.ipv4.ip_forward=1
  iptables -t nat -A POSTROUTING -s "$SUBNET" ! -o "$BR" -j MASQUERADE
  # Docker sets the FORWARD policy to DROP, so explicitly allow the bridge traffic.
  iptables -I FORWARD -i "$BR" -j ACCEPT
  iptables -I FORWARD -o "$BR" -j ACCEPT
  echo "up: red=10.0.0.2 blue=10.0.0.3 gw=$GW"
}

test_() {
  ip netns exec red ping -c 2 10.0.0.3
  ip netns exec red ping -c 2 "$GW"
  ip netns exec red ping -c 2 1.1.1.1 || echo "(outbound failed: check the NAT rule and uplink)"
}

down() {
  iptables -t nat -D POSTROUTING -s "$SUBNET" ! -o "$BR" -j MASQUERADE 2>/dev/null || true
  iptables -D FORWARD -i "$BR" -j ACCEPT 2>/dev/null || true
  iptables -D FORWARD -o "$BR" -j ACCEPT 2>/dev/null || true
  for ns in red blue; do ip netns del "$ns" 2>/dev/null || true; done
  ip link del "$BR" 2>/dev/null || true
  echo "down"
}

case "${1:-}" in
  up) up ;;
  test) test_ ;;
  down) down ;;
  *) echo "usage: $0 up|test|down" >&2; exit 1 ;;
esac

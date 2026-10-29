#!/usr/bin/env bash
# k3d cluster + an FRR "top of rack" router on the same docker network, peered via MetalLB.
set -euo pipefail
cd "$(dirname "$0")"

CLUSTER=bgp
METALLB_VERSION=v0.14.8
FRR_IMAGE=quay.io/frrouting/frr:9.1.0

# Default flannel is fine here. servicelb (klipper) is disabled because MetalLB replaces it.
k3d cluster create "$CLUSTER" \
  --agents 1 \
  --servers-memory 1.5g \
  --agents-memory 1g \
  --k3s-arg "--disable=servicelb@server:*" \
  --k3s-arg "--disable=traefik@server:*"

NET="k3d-$CLUSTER"
SUBNET=$(docker network inspect "$NET" -f '{{(index .IPAM.Config 0).Subnet}}')

# Start the router first to learn the IP docker gives it, then write the config and restart.
: > frr.conf
docker run -d --name tor --network "$NET" --privileged \
  -v "$PWD/daemons:/etc/frr/daemons:ro" \
  -v "$PWD/frr.conf:/etc/frr/frr.conf" \
  "$FRR_IMAGE" >/dev/null
ROUTER_IP=$(docker inspect tor -f "{{(index .NetworkSettings.Networks \"$NET\").IPAddress}}")
# Write in place (same inode) so the bind mount sees the new contents.
sed -e "s|__ROUTER_IP__|$ROUTER_IP|" -e "s|__SUBNET__|$SUBNET|" frr.conf.tmpl > frr.conf
docker restart tor >/dev/null

kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/$METALLB_VERSION/config/manifests/metallb-native.yaml"
kubectl -n metallb-system wait --for=condition=ready pod -l app=metallb --timeout=180s
sed "s|__ROUTER_IP__|$ROUTER_IP|" metallb.yaml.tmpl | kubectl apply -f -

kubectl apply -f demo.yaml
echo
echo "router tor = $ROUTER_IP on $SUBNET"
echo "next: docker exec tor vtysh -c 'show bgp summary'"

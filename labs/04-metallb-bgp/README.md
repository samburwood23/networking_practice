# Lab 04 – MetalLB in BGP mode against an FRR router

A k3d cluster (one server, one agent) shares a docker network with an FRR container, `tor`,
which plays the top-of-rack router. MetalLB's speakers peer with it and advertise
LoadBalancer IPs from `10.100.0.0/24` as /32 routes.

```
            tor (FRR, AS 64512)
           /                   \
  k3d-bgp-server-0        k3d-bgp-agent-0     <- MetalLB speakers, AS 64513
           \                   /
        Service web: 10.100.0.x (LoadBalancer)
```

Expect about 2.5 GB in use. Delete anything else that's running first.

## Run it

```bash
./up.sh
kubectl get svc web                               # EXTERNAL-IP from 10.100.0.0/24
docker exec tor vtysh -c "show bgp summary"       # two established sessions
docker exec tor vtysh -c "show ip route bgp"      # the /32 with two next hops (ECMP)
docker exec tor wget -qO- http://<EXTERNAL-IP>    # nginx answers from the router
```

## Things to try

- Set `externalTrafficPolicy: Local` on the service and scale to 1 replica. Only the node
  running the pod should keep advertising the route.
- `kubectl cordon` and drain the agent: watch the next hop disappear on `tor`.
- Add `communities` or `localPref` to the `BGPAdvertisement` and find them in
  `show bgp ipv4 unicast <ip>/32`.
- Swap flannel for Cilium (see Lab 02) and use Cilium's own BGP control plane instead of MetalLB.

## Clean up

```bash
./down.sh
```

# Lab 03 – Containerlab + FRR

Two FRR routers in different ASes peer over eBGP. Each one advertises the LAN behind it.
The whole lab is four small containers, well under 300 MB.

```
h1 192.168.1.10 ── r1 (AS 65001) ──10.0.12.0/30── r2 (AS 65002) ── h2 192.168.2.10
```

## Run it

```bash
bash -c "$(curl -sL https://get.containerlab.dev)"   # once
sudo containerlab deploy -t topology.clab.yml
```

Check the BGP session and the learned routes:

```bash
docker exec clab-frr-bgp-r1 vtysh -c "show bgp summary"
docker exec clab-frr-bgp-r1 vtysh -c "show ip route bgp"
docker exec clab-frr-bgp-h1 ping -c 3 192.168.2.10
```

## Things to try

- `docker exec clab-frr-bgp-r1 tcpdump -ni eth1 tcp port 179` while you run
  `vtysh -c "clear bgp *"`: watch OPEN, UPDATE and KEEPALIVE go by.
- Take the link down (`docker exec clab-frr-bgp-r2 ip link set eth1 down`) and time how long r1
  takes to withdraw the route. Then lower the timers with `neighbor ... timers 3 9` and compare.
- Add a route-map on r2 that prepends its AS twice, and look at the AS path on r1.
- Add an r3 to make a triangle. Use `maximum-paths` and see ECMP in `ip route`.

## Clean up

```bash
sudo containerlab destroy -t topology.clab.yml --cleanup
```

# Lab 01 – Network namespaces and veth pairs

You don't need Docker or Kubernetes for this one, just `iproute2` and root.
Underneath, this is how every container network works.

```bash
sudo ./lab.sh up      # build the topology
sudo ./lab.sh test    # ping across it
sudo ./lab.sh down    # tear it down
```

## Topology

```
  ns red (10.0.0.2) ──veth──┐
                            ├── br0 (10.0.0.1, host) ── NAT ── host uplink
  ns blue (10.0.0.3) ─veth──┘
```

## Things to try

- `sudo ip netns exec red ip addr` / `ip route`: what does a container see?
- `sudo tcpdump -i br0 -n` while red pings blue: watch the ARP and then the ICMP.
- `bridge fdb show br br0`: the MAC table the bridge has learned.
- Delete the default route in `red` and see what breaks (and what still works).
- Remove the MASQUERADE rule and try `ip netns exec red ping 1.1.1.1`.

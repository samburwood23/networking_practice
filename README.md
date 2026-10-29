# networking_practice

Hands-on Linux and Kubernetes networking labs, sized for a machine with about 8 GB RAM
(some of it reserved for graphics). That's tight but workable if you keep things lean.

## Ground rules for a small machine

- Use **k3d** (k3s in Docker), not kind. k3s is noticeably lighter. A server plus one
  agent fits, and a single node is enough for most labs.
- Run **one lab at a time**. Run `k3d cluster delete <name>` before you start the next one.
- Keep `htop` or `watch free -h` open in a spare terminal so you can see when you're close to swapping.

## What runs where

| Lab / topic | Where | Notes |
|---|---|---|
| Network namespaces, veth, bridges | Local | Costs almost nothing. Start here. |
| k3d with no CNI, then install Cilium | Local | Nodes stay `NotReady` until the CNI is installed. |
| Containerlab + FRR | Local | Routers are tiny containers. |
| MetalLB in BGP mode peering with an FRR router | Local | Use a small cluster (1 server, 0–1 agents). |
| Vault integration | Local | Dev mode only: single pod, in-memory. |
| Service mesh | Local: Linkerd | Istio is too heavy for this machine. |
| Istio | Cloud | Short-lived GKE cluster, deleted afterwards. |
| Kubernetes the Hard Way | Cloud | Three VMs won't fit next to a desktop. Use small GCP VMs (destroy afterwards) or the Oracle free tier. |
| Anything you want running for days | Cloud | |

## Getting started

```bash
./scripts/setup.sh        # installs docker + k3d; log out and back in afterwards
```

Then work through the labs in order:

1. [`labs/01-netns-veth`](labs/01-netns-veth/) – namespaces, veth pairs, a bridge, NAT
2. [`labs/02-k3d-cilium`](labs/02-k3d-cilium/) – CNI-less k3d cluster, then install Cilium yourself
3. [`labs/03-containerlab-frr`](labs/03-containerlab-frr/) – two FRR routers peering over eBGP
4. [`labs/04-metallb-bgp`](labs/04-metallb-bgp/) – MetalLB in BGP mode peering with an FRR router

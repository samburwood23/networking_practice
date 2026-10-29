# Lab 02 – k3d with no CNI, then Cilium

The cluster starts with flannel and k3s's network policy controller disabled, so there's no CNI.
The nodes will sit `NotReady` until you install one, and that's your first real task.

```bash
./create-cluster.sh
kubectl get nodes              # NotReady: expected
```

## Install Cilium

Install the [cilium CLI](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli), then:

```bash
cilium install
cilium status --wait
kubectl get nodes              # should now be Ready
cilium connectivity test       # optional, takes a while and uses some RAM
```

If the Cilium agents crash-loop with BPF filesystem or cgroup mount errors,
k3d's node containers need shared mounts:

```bash
for n in k3d-lab-server-0 k3d-lab-agent-0; do
  docker exec "$n" mount bpffs /sys/fs/bpf -t bpf
  docker exec "$n" mount --make-shared /sys/fs/bpf
  docker exec "$n" mkdir -p /run/cilium/cgroupv2
  docker exec "$n" mount -t cgroup2 none /run/cilium/cgroupv2
  docker exec "$n" mount --make-shared /run/cilium/cgroupv2
done
kubectl -n kube-system rollout restart ds/cilium
```

## Things to try

- `kubectl -n kube-system exec ds/cilium -- cilium-dbg status`, then `cilium-dbg endpoint list`
- Write a `CiliumNetworkPolicy` that only lets one pod reach another on one port.
- Enable Hubble (`cilium hubble enable --ui`) and watch the flows. Turn it off afterwards if RAM is tight.
- From the host, `docker exec k3d-lab-agent-0 ip link`: find the pod's veth on the node.

## Clean up

```bash
k3d cluster delete lab
```

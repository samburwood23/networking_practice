#!/usr/bin/env bash
# One server + one agent, no CNI, no traefik. Memory caps keep it from eating the desktop.
set -euo pipefail

k3d cluster create lab \
  --agents 1 \
  --servers-memory 1.5g \
  --agents-memory 1g \
  --k3s-arg "--flannel-backend=none@server:*" \
  --k3s-arg "--disable-network-policy@server:*" \
  --k3s-arg "--disable=traefik@server:*"

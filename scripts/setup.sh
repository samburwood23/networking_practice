#!/usr/bin/env bash
# Install the base tooling: Docker and k3d.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y docker.io htop iproute2 iputils-ping tcpdump

# Note: membership of the docker group is effectively root access on this machine.
sudo usermod -aG docker "$USER"

if ! command -v k3d >/dev/null; then
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo
echo "Done. Log out and back in (or run 'newgrp docker') so the docker group takes effect."

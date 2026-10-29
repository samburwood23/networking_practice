#!/usr/bin/env bash
set -euo pipefail
docker rm -f tor 2>/dev/null || true
rm -f "$(dirname "$0")/frr.conf"
k3d cluster delete bgp

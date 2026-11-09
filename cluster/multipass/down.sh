#!/usr/bin/env bash
set -euo pipefail
multipass delete --purge k3s-server k3s-agent-1 k3s-agent-2 2>/dev/null || true
rm -f "$(dirname "$0")/../../kubeconfig"
echo "lab removed"

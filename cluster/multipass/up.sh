#!/usr/bin/env bash
# Creates a real 3-node k3s cluster in Multipass VMs (macOS, Windows, Linux).
#   1 server (control plane) + 2 agents, then writes ./kubeconfig
set -euo pipefail

K3S_VERSION="${K3S_VERSION:-v1.31.5+k3s1}"
SERVER="k3s-server"
AGENTS=(k3s-agent-1 k3s-agent-2)
CPUS="${CPUS:-2}"; MEM="${MEM:-2G}"; DISK="${DISK:-10G}"
cd "$(dirname "$0")/../.."

command -v multipass >/dev/null || { echo "install multipass: https://multipass.run" >&2; exit 1; }

launch() {
  if multipass info "$1" >/dev/null 2>&1; then echo "$1 exists"; return; fi
  multipass launch 24.04 --name "$1" --cpus "$CPUS" --memory "$MEM" --disk "$DISK"
}

launch "$SERVER"
multipass exec "$SERVER" -- bash -c \
  "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='$K3S_VERSION' sh -s - server --write-kubeconfig-mode 0644"
SERVER_IP="$(multipass info "$SERVER" --format json | jq -r ".info[\"$SERVER\"].ipv4[0]")"
TOKEN="$(multipass exec "$SERVER" -- sudo cat /var/lib/rancher/k3s/server/node-token)"

for agent in "${AGENTS[@]}"; do
  launch "$agent"
  multipass exec "$agent" -- bash -c \
    "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='$K3S_VERSION' K3S_URL='https://$SERVER_IP:6443' K3S_TOKEN='$TOKEN' sh -"
done

multipass exec "$SERVER" -- cat /etc/rancher/k3s/k3s.yaml | sed "s/127.0.0.1/$SERVER_IP/" > kubeconfig
chmod 600 kubeconfig
echo
echo "cluster ready:  export KUBECONFIG=$PWD/kubeconfig && kubectl get nodes -o wide"
echo "ingress:        http://$SERVER_IP  (add '$SERVER_IP whoami.lab' to /etc/hosts)"

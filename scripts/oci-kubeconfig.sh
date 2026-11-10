#!/usr/bin/env bash
# Fetches the kubeconfig of the OCI cluster into ./kubeconfig-oci.
# The API server is not reachable from the internet: run `make oci-tunnel` in a second terminal.
set -euo pipefail
cd "$(dirname "$0")/.."

ip="$(terraform -chdir=infra/oci output -raw server_public_ip)"

# cloud-init installs k3s after the first boot, so wait for the file instead of failing.
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${ip}" \
  'timeout 600 sh -c "until sudo test -s /etc/rancher/k3s/k3s.yaml; do sleep 5; done"; sudo cat /etc/rancher/k3s/k3s.yaml' \
  > kubeconfig-oci
chmod 600 kubeconfig-oci

echo "kubeconfig written (server https://127.0.0.1:6443, through the tunnel)"
echo "  make oci-tunnel                      # second terminal"
echo "  KUBECONFIG=\$PWD/kubeconfig-oci kubectl get nodes -o wide"

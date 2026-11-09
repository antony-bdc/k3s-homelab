# k3s-lab

A 3-node Kubernetes lab with [k3s](https://k3s.io) and an app deployed the way it should be in production:
non-root, network-isolated, autoscaled, and updated without dropping a single request.
CI builds a real cluster on every push and **proves** those properties with an end-to-end test.

```mermaid
flowchart LR
    U((browser)) -->|whoami.localhost| T[Traefik ingress<br/>kube-system]
    subgraph lab namespace · PSA restricted
      T -->|only allowed source| S[Service]
      S --> P1[pod] & P2[pod]
      H[HPA 2-6] -.-> P1 & P2
      X[other namespaces] -. blocked by NetworkPolicy .-x S
    end
```

## Two ways to run the cluster

| | Command | What you get |
|---|---|---|
| **VMs** | `make vm-up` | 1 server + 2 agents as Ubuntu VMs in [Multipass](https://multipass.run) (macOS, Windows, Linux) |
| **Docker** | `make up` | same shape in containers with [k3d](https://k3d.io), starts in ~30 s, used by CI |

```bash
make up          # cluster
make deploy      # kubectl apply -k apps/whoami/overlays/lab
make test        # smoke test below
curl -H "Host: whoami.localhost" http://localhost:8080
```

## What the deployment does

| Concern | How |
|---|---|
| Security | non-root UID, read-only root filesystem, all capabilities dropped, seccomp, no service-account token, namespace enforces Pod Security *restricted* |
| Network | default-deny NetworkPolicy, only Traefik may reach the pods |
| Availability | ≥ 2 replicas spread across nodes, PodDisruptionBudget, `maxUnavailable: 0` rolling updates, readiness probe + `preStop` delay |
| Scaling | HorizontalPodAutoscaler on CPU (k3s ships metrics-server) |
| Environments | Kustomize base + overlays: `lab` and `prod-like` (3 replicas, strict spreading, own host and config) |

## The smoke test

`scripts/smoke-test.sh` runs against any cluster and checks behaviour, not just YAML:

1. the app answers through the ingress,
2. a pod in another namespace **cannot** reach it directly (NetworkPolicy works),
3. a rolling restart under constant load produces **0 failed requests**,
4. deleting a pod under load produces **0 failed requests**.

CI runs `make validate` (kustomize build + kubeconform strict schema check + shellcheck) and then the
full smoke test on a fresh k3d cluster.

## Design decisions

- **Kustomize over Helm** for a single in-house app: plain YAML that `kubectl` understands, environment differences as small, reviewable patches.
- **Explicit selectors.** Kustomize's `includeSelectors` would also rewrite the Traefik selector inside the NetworkPolicy and silently block all traffic, so selectors are written out and only pod templates get the common labels.
- **Test the promises.** "Zero-downtime" and "isolated" are claims; the smoke test turns them into checks that fail the build.

## Possible next steps

GitOps with Argo CD or Flux, and the [homelab-monitoring](https://github.com/businessantonybdc-crypto/homelab-monitoring) stack on the cluster via kube-prometheus-stack.

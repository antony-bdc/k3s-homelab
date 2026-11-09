#!/usr/bin/env bash
# Proves the deployment behaves as designed, against a running cluster:
#   1. reachable through the ingress
#   2. NetworkPolicy blocks direct access from other namespaces
#   3. a rolling update causes zero failed requests
#   4. killing a pod causes zero failed requests
set -euo pipefail

NS="${NS:-lab}"
URL="${URL:-http://localhost:8080/}"
HOST="${HOST:-whoami.localhost}"

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; exit 1; }
req()  { curl -fsS -m 3 -H "Host: $HOST" "$URL"; }

# Sends requests for $1 seconds in the background, writes the number of failures to $2.
load() {
  local seconds="$1" out="$2" end failures=0
  end=$(( $(date +%s) + seconds ))
  while (( $(date +%s) < end )); do
    req >/dev/null 2>&1 || failures=$((failures + 1))
    sleep 0.1
  done
  echo "$failures" > "$out"
}

echo "smoke test (namespace $NS)"
kubectl -n "$NS" rollout status deploy/whoami --timeout=120s >/dev/null

# Traefik needs a moment to pick up a new ingress.
for _ in $(seq 1 30); do req >/dev/null 2>&1 && break; sleep 2; done
if req | grep -q '^Name: '; then pass "reachable through the ingress"; else fail "ingress"; fi

if kubectl run np-probe --rm -i --restart=Never -n default --image=curlimages/curl:8.10.1 --quiet -- \
     curl -sS -m 5 "http://whoami.$NS.svc/" >/dev/null 2>&1; then
  fail "NetworkPolicy should block access from other namespaces"
else
  pass "direct access from another namespace is blocked"
fi

tmp="$(mktemp)"
load 45 "$tmp" &
kubectl -n "$NS" rollout restart deploy/whoami >/dev/null
kubectl -n "$NS" rollout status deploy/whoami --timeout=120s >/dev/null
wait
check_zero() { if [[ "$(cat "$tmp")" -eq 0 ]]; then pass "$1: 0 failed requests"; else fail "$1: $(cat "$tmp") failed requests"; fi; }
check_zero "rolling update"

load 25 "$tmp" &
victim="$(kubectl -n "$NS" get pod -l app.kubernetes.io/name=whoami -o name | head -1)"
kubectl -n "$NS" delete "$victim" --wait=false >/dev/null
wait
check_zero "pod killed"
rm -f "$tmp"

echo "all checks passed"

.PHONY: validate up deploy test down vm-up vm-down

OVERLAY ?= lab

validate: ## render and schema-check every overlay
	@for o in apps/whoami/overlays/*; do \
	  echo "== $$o"; kustomize build $$o | kubeconform -strict -summary -kubernetes-version 1.31.0 - || exit 1; \
	done
	shellcheck scripts/*.sh cluster/multipass/*.sh

up: ## k3d cluster in Docker (fast)
	k3d cluster create --config cluster/k3d/k3d.yaml

deploy:
	kubectl apply -k apps/whoami/overlays/$(OVERLAY)

test:
	NS=$(OVERLAY) scripts/smoke-test.sh

down:
	k3d cluster delete lab

vm-up: ## real VMs with Multipass
	cluster/multipass/up.sh

vm-down:
	cluster/multipass/down.sh

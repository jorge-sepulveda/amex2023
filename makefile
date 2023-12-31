# Check to see if we can use ash, in Alpine images, or default to BASH.
SHELL_PATH = /bin/ash
SHELL = $(if $(wildcard $(SHELL_PATH)),/bin/ash,/bin/bash)

# ==============================================================================
# CLASS NOTES
#
# Kind
# 	For full Kind v0.20 release notes: https://github.com/kubernetes-sigs/kind/releases/tag/v0.20.0
#
# RSA Keys
# 	To generate a private/public key PEM file.
# 	$ openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048
# 	$ openssl rsa -pubout -in private.pem -out public.pem
# 	$ ./sales-admin genkey

admin:
	go run app/tooling/sales-admin/main.go

admin-21:
	go1.21.4 run app/tooling/sales-admin/main.go

run:
	go run app/services/sales-api/main.go | go run app/tooling/logfmt/main.go

run-21:
	go1.21.4 run app/services/sales-api/main.go | go1.21.4 run app/tooling/logfmt/main.go

run-help:
	go run app/services/sales-api/main.go --help

run-help-21:
	go1.21.4 run app/services/sales-api/main.go --help

install:
	go install golang.org/dl/go1.21.4@latest
	go1.21.4 download

curl:
	curl -il http://localhost:3000/test

curl-auth:
	curl -il -H "Authorization: Bearer ${TOKEN}" http://localhost:3000/auth

load:
	hey -m GET -c 100 -n 1000 http://localhost:3000/test

live:
	curl -il http://localhost:3000/liveness

ready:
	curl -il http://localhost:3000/readiness

# ==============================================================================
# Define dependencies

GOLANG          := golang:1.21.4
ALPINE          := alpine:3.18
KIND            := kindest/node:v1.27.3
POSTGRES        := postgres:15.5
VAULT           := hashicorp/vault:1.15
GRAFANA         := grafana/grafana:10.2.0
PROMETHEUS      := prom/prometheus:v2.48.0
TEMPO           := grafana/tempo:2.3.0
LOKI            := grafana/loki:2.9.0
PROMTAIL        := grafana/promtail:2.9.0

KIND_CLUSTER    := ardan-starter-cluster
NAMESPACE       := sales-system
APP             := sales
BASE_IMAGE_NAME := ardanlabs/service
SERVICE_NAME    := sales-api
VERSION         := 0.0.1
SERVICE_IMAGE   := $(BASE_IMAGE_NAME)/$(SERVICE_NAME):$(VERSION)
METRICS_IMAGE   := $(BASE_IMAGE_NAME)/$(SERVICE_NAME)-metrics:$(VERSION)

# VERSION       := "0.0.1-$(shell git rev-parse --short HEAD)"

# ==============================================================================
# Building containers

all: service

all-aexp: service-aexp

service:
	docker build \
		-f zarf/docker/dockerfile.service \
		-t $(SERVICE_IMAGE) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

service-aexp:
	docker build \
		-f zarf/docker/dockerfile.aexp \
		-t $(SERVICE_IMAGE) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

# ==============================================================================
# Running from within k8s/kind

dev-up:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/dev/kind-config.yaml

	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

dev-down:
	kind delete cluster --name $(KIND_CLUSTER)

dev-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

# ------------------------------------------------------------------------------

dev-load:
	kind load docker-image $(SERVICE_IMAGE) --name $(KIND_CLUSTER)

dev-apply:
	kustomize build zarf/k8s/dev/sales | kubectl apply -f -
	kubectl wait pods --namespace=$(NAMESPACE) --selector app=$(APP) --timeout=120s --for=condition=Ready

dev-restart:
	kubectl rollout restart deployment $(APP) --namespace=$(NAMESPACE)

dev-update: all dev-load dev-restart

dev-update-apply: all dev-load dev-apply

dev-update-aexp: all-aexp dev-load dev-restart

dev-update-apply-aexp: all-aexp dev-load dev-apply

dev-logs:
	kubectl logs --namespace=$(NAMESPACE) -l app=$(APP) --all-containers=true -f --tail=100 --max-log-requests=6 | go run app/tooling/logfmt/main.go -service=$(SERVICE_NAME)

dev-logs-21:
	kubectl logs --namespace=$(NAMESPACE) -l app=$(APP) --all-containers=true -f --tail=100 --max-log-requests=6 | go1.21.4 run app/tooling/logfmt/main.go -service=$(SERVICE_NAME)

# ------------------------------------------------------------------------------

dev-describe-deployment:
	kubectl describe deployment --namespace=$(NAMESPACE) $(APP)

dev-describe-sales:
	kubectl describe pod --namespace=$(NAMESPACE) -l app=$(APP)

# ==============================================================================
# Modules support

tidy:
	go mod tidy
	go mod vendor

# ==============================================================================
# Metrics and Tracing

metrics-view:
	expvarmon -ports="localhost:4000" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"

statsviz:
	open -a "Google Chrome" http://localhost:4000/debug/statsviz

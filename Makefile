# ============================================================
# Variables — override via environment or CLI
#   make deploy IMAGE_TAG=abc123
# ============================================================
PROJECT_ID   ?= project-87677895-1a10-4291-8ac
REGION       ?= asia-northeast1
SERVICE_NAME ?= sales-daily-report-app
REPOSITORY   ?= sales-daily-report
IMAGE_TAG    ?= latest

IMAGE := $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPOSITORY)/$(SERVICE_NAME):$(IMAGE_TAG)

# ============================================================
# Phony targets
# ============================================================
.PHONY: help build push deploy deploy-all setup-artifact-registry

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

# ============================================================
# Docker
# ============================================================
build: ## Build Docker image locally
	docker build -t $(IMAGE) .

push: ## Push image to Artifact Registry
	docker push $(IMAGE)

# ============================================================
# Cloud Run
# ============================================================
deploy: ## Deploy existing image to Cloud Run
	gcloud run deploy $(SERVICE_NAME) \
	  --image $(IMAGE) \
	  --region $(REGION) \
	  --platform managed \
	  --allow-unauthenticated \
	  --port 8080 \
	  --project $(PROJECT_ID)

deploy-all: build push deploy ## Build, push, and deploy in one step

# ============================================================
# Setup (run once)
# ============================================================
setup-artifact-registry: ## Create Artifact Registry repository
	gcloud artifacts repositories create $(REPOSITORY) \
	  --repository-format docker \
	  --location $(REGION) \
	  --project $(PROJECT_ID)
	gcloud auth configure-docker $(REGION)-docker.pkg.dev

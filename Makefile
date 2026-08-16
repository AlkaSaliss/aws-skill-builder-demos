.PHONY: help install-tools fmt init validate plan apply destroy batch-image-push

AWS_PROFILE ?= cli-mfa-user
AWS_REGION ?= us-east-1
STACK ?= step-functions-baseline
ECR_REPOSITORY ?= aws-skill-builder-batch-hello-world
IMAGE_TAG ?= latest
IMAGE_CONTEXT ?= resources/batch-hello-world
DOCKER_PLATFORM ?= linux/amd64

ENVIRONMENT := dev
LIVE_DIR := live/$(ENVIRONMENT)/$(AWS_REGION)/$(STACK)

export AWS_PROFILE AWS_REGION

help:
	@printf '%s\n' \
		'install-tools  Install versions pinned in .tool-versions with asdf' \
		'fmt       Format Terraform and Terragrunt files' \
		'init      Initialize the selected live stack' \
		'validate  Validate the selected live stack' \
		'plan      Preview changes without applying them' \
		'apply     Apply the selected stack changes' \
		'destroy   Destroy resources in the selected stack' \
		'batch-image-push  Build and push the Batch image to ECR' \
		'' \
		'AWS_PROFILE=cli-mfa-user AWS_REGION=us-east-1 STACK=step-functions-baseline' \
		'ECR_REPOSITORY=aws-skill-builder-batch-hello-world IMAGE_TAG=latest DOCKER_PLATFORM=linux/amd64'

# Install repository-pinned tools without changing global asdf defaults.
install-tools:
	asdf install

fmt:
	terraform fmt -recursive .
	terragrunt hcl fmt

init:
	cd $(LIVE_DIR) && terragrunt init

validate:
	cd $(LIVE_DIR) && terragrunt validate

# Preview the selected stack's changes without modifying infrastructure.
plan:
	cd $(LIVE_DIR) && terragrunt plan

# Apply the selected stack after Terragrunt's interactive approval.
apply:
	cd $(LIVE_DIR) && terragrunt apply

# Destroy the selected stack after Terragrunt's interactive approval.
destroy:
	cd $(LIVE_DIR) && terragrunt destroy

batch-image-push:
	@set -eu; \
	account_id=$$(aws sts get-caller-identity --profile "$(AWS_PROFILE)" --query Account --output text); \
	registry="$$account_id.dkr.ecr.$(AWS_REGION).amazonaws.com"; \
	aws ecr get-login-password --profile "$(AWS_PROFILE)" --region "$(AWS_REGION)" | docker login --username AWS --password-stdin "$$registry"; \
	docker build --platform "$(DOCKER_PLATFORM)" --tag "$$registry/$(ECR_REPOSITORY):$(IMAGE_TAG)" "$(IMAGE_CONTEXT)"; \
	docker push "$$registry/$(ECR_REPOSITORY):$(IMAGE_TAG)"

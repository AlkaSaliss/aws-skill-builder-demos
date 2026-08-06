.PHONY: help install-tools fmt init validate plan apply destroy

AWS_PROFILE ?= cli-mfa-user
AWS_REGION ?= us-east-1
STACK ?= step-functions-baseline

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
		'' \
		'AWS_PROFILE=CLI-MFA-USER AWS_REGION=us-east-1 STACK=step-functions-baseline'

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

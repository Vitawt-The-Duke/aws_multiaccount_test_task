# Makefile for Terraform operations
# Simplifies common Terraform commands with proper AWS profile configuration

# Default values
ACCOUNT_A_PROFILE ?= ACCOUNT_A
ACCOUNT_B_PROFILE ?= ACCOUNT_B
ENV ?= prod
TERRAFORM_DIR = envs/$(ENV)

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

.PHONY: help init plan apply destroy validate fmt clean

help: ## Show this help message
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

init: ## Initialize Terraform with backend configuration
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	@echo "$(YELLOW)Using profiles: ACCOUNT_A=$(ACCOUNT_A_PROFILE), ACCOUNT_B=$(ACCOUNT_B_PROFILE)$(NC)"
	terraform -chdir=$(TERRAFORM_DIR) init

init-backend: ## Initialize Terraform with backend config file (requires backend.hcl)
	@echo "$(GREEN)Initializing Terraform with backend configuration...$(NC)"
	@if [ ! -f $(TERRAFORM_DIR)/backend.hcl ]; then \
		echo "$(RED)Error: backend.hcl not found in $(TERRAFORM_DIR)$(NC)"; \
		echo "$(YELLOW)Copy backend.hcl.example to backend.hcl and customize$(NC)"; \
		exit 1; \
	fi
	terraform -chdir=$(TERRAFORM_DIR) init -backend-config=backend.hcl

validate: ## Validate Terraform configuration
	@echo "$(GREEN)Validating Terraform configuration...$(NC)"
	terraform -chdir=$(TERRAFORM_DIR) validate

fmt: ## Format Terraform files
	@echo "$(GREEN)Formatting Terraform files...$(NC)"
	terraform fmt -recursive

fmt-check: ## Check Terraform formatting without making changes
	@echo "$(GREEN)Checking Terraform formatting...$(NC)"
	terraform fmt -check -recursive

lint: ## Run tflint
	@echo "$(GREEN)Running tflint...$(NC)"
	@if ! command -v tflint >/dev/null 2>&1; then \
		echo "$(YELLOW)tflint not found. Installing...$(NC)"; \
		tflint --init; \
	fi
	tflint --chdir=$(TERRAFORM_DIR)

plan: ## Run Terraform plan
	@echo "$(GREEN)Running Terraform plan...$(NC)"
	@echo "$(YELLOW)Using profiles: ACCOUNT_A=$(ACCOUNT_A_PROFILE), ACCOUNT_B=$(ACCOUNT_B_PROFILE)$(NC)"
	terraform -chdir=$(TERRAFORM_DIR) plan

plan-destroy: ## Run Terraform plan for destroy
	@echo "$(GREEN)Running Terraform plan for destroy...$(NC)"
	@echo "$(YELLOW)Using profiles: ACCOUNT_A=$(ACCOUNT_A_PROFILE), ACCOUNT_B=$(ACCOUNT_B_PROFILE)$(NC)"
	terraform -chdir=$(TERRAFORM_DIR) plan -destroy

apply: ## Apply Terraform changes
	@echo "$(GREEN)Applying Terraform changes...$(NC)"
	@echo "$(YELLOW)Using profiles: ACCOUNT_A=$(ACCOUNT_A_PROFILE), ACCOUNT_B=$(ACCOUNT_B_PROFILE)$(NC)"
	@read -p "$(YELLOW)Are you sure you want to apply? [y/N]$(NC) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		terraform -chdir=$(TERRAFORM_DIR) apply; \
	fi

apply-auto: ## Apply Terraform changes without confirmation
	@echo "$(GREEN)Applying Terraform changes (auto-approve)...$(NC)"
	@echo "$(YELLOW)Using profiles: ACCOUNT_A=$(ACCOUNT_A_PROFILE), ACCOUNT_B=$(ACCOUNT_B_PROFILE)$(NC)"
	terraform -chdir=$(TERRAFORM_DIR) apply -auto-approve

destroy: ## Destroy Terraform resources
	@echo "$(RED)WARNING: This will destroy all resources!$(NC)"
	@echo "$(YELLOW)Using profiles: ACCOUNT_A=$(ACCOUNT_A_PROFILE), ACCOUNT_B=$(ACCOUNT_B_PROFILE)$(NC)"
	@read -p "$(RED)Are you absolutely sure? Type 'yes' to confirm:$(NC) " -r; \
	if [ "$$REPLY" != "yes" ]; then \
		echo "$(YELLOW)Destroy cancelled$(NC)"; \
		exit 1; \
	fi
	terraform -chdir=$(TERRAFORM_DIR) destroy

output: ## Show Terraform outputs
	@echo "$(GREEN)Showing Terraform outputs...$(NC)"
	terraform -chdir=$(TERRAFORM_DIR) output

output-json: ## Show Terraform outputs in JSON format
	@echo "$(GREEN)Showing Terraform outputs (JSON)...$(NC)"
	terraform -chdir=$(TERRAFORM_DIR) output -json

clean: ## Clean Terraform files (.terraform, .terraform.lock.hcl)
	@echo "$(GREEN)Cleaning Terraform files...$(NC)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)Clean complete$(NC)"

# Note: The providers.tf file uses AWS profiles configured in ~/.aws/credentials
# Make sure you have profiles set up:
# [profile ACCOUNT_A]
# aws_access_key_id = ...
# aws_secret_access_key = ...
# region = eu-central-1
#
# [profile ACCOUNT_B]
# aws_access_key_id = ...
# aws_secret_access_key = ...
# region = eu-central-1


# Terraform Backend Configuration
# This file configures the remote state backend (S3 + DynamoDB)
# 
# IMPORTANT: Backend configuration cannot use variables. You must either:
# 1. Replace the placeholder values below with your actual backend configuration
# 2. Use -backend-config flags during terraform init
# 3. Create a backend.hcl file and use: terraform init -backend-config=backend.hcl
#
# REQUIRED SETUP STEPS:
# 1. Create an S3 bucket for Terraform state (in Account A recommended)
# 2. Create a DynamoDB table for state locking
# 3. Configure bucket versioning and encryption
# 4. Update the values below or use -backend-config flags
#
# Example initialization with -backend-config:
# terraform init \
#   -backend-config="bucket=your-terraform-state-bucket" \
#   -backend-config="key=prod/iam/terraform.tfstate" \
#   -backend-config="region=eu-central-1" \
#   -backend-config="dynamodb_table=terraform-state-lock" \
#   -backend-config="encrypt=true"
#
# Or create backend.hcl file with:
# bucket         = "your-terraform-state-bucket"
# key            = "prod/iam/terraform.tfstate"
# region         = "eu-central-1"
# dynamodb_table = "terraform-state-lock"
# encrypt        = true
# kms_key_id     = "arn:aws:kms:region:account:key/key-id"  # Optional: for KMS encryption
#
# Then: terraform init -backend-config=backend.hcl

terraform {
  backend "s3" {
    # REPLACE THESE PLACEHOLDER VALUES WITH YOUR ACTUAL BACKEND CONFIGURATION
    # Or remove them and use -backend-config flags during init
    
    bucket         = "REPLACE-WITH-YOUR-TERRAFORM-STATE-BUCKET"
    key            = "prod/iam/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "REPLACE-WITH-YOUR-DYNAMODB-TABLE"
    encrypt        = true
    
    # Optional: Use a specific profile for backend access (recommended)
    # This should be the profile for Account A (management account)
    # profile = "ACCOUNT_A"
    
    # Optional: Use KMS encryption for additional security
    # kms_key_id = "arn:aws:kms:eu-central-1:000000000000:key/your-key-id"
    
    # Optional: Enable versioning on the state bucket (recommended)
    # This is configured on the S3 bucket itself, not here
  }
}


# Terraform Backend Configuration
# This file configures the remote state backend (S3 + DynamoDB)
# 
# Note: The backend configuration uses variables, but Terraform requires
# backend configuration to be static. To use this backend:
# 1. Create terraform.tfvars with actual values
# 2. Use terraform init -backend-config=backend.hcl (if using .hcl file)
# 3. Or use -backend-config flags during init
#
# For this example, we use a placeholder configuration that should be
# customized based on your actual backend setup.

terraform {
  backend "s3" {
    # These values should be provided via -backend-config flags or backend.hcl
    # Example: terraform init -backend-config="bucket=my-terraform-state" \
    #                          -backend-config="key=prod/iam/terraform.tfstate" \
    #                          -backend-config="region=eu-central-1" \
    #                          -backend-config="dynamodb_table=terraform-state-lock"
    
    bucket         = "terraform-state-bucket-placeholder"
    key            = "prod/iam/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    
    # Optional: Use a specific profile for backend access
    # profile = "ACCOUNT_A"
  }
}

# Alternative: If you prefer to keep backend configuration in a separate file
# Create backend.hcl with:
# bucket         = "your-terraform-state-bucket"
# key            = "prod/iam/terraform.tfstate"
# region         = "eu-central-1"
# dynamodb_table = "your-terraform-state-lock-table"
# encrypt        = true
#
# Then initialize with: terraform init -backend-config=backend.hcl


# AWS Provider Configuration
# This file configures two AWS providers for multi-account access

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Default provider: Account A (management account)
# This provider uses the ACCOUNT_A profile from ~/.aws/credentials or ~/.aws/config
# To use a different profile name, modify the profile argument below
provider "aws" {
  alias   = "a"
  region  = var.region_a
  profile = "ACCOUNT_A"  # Change this to match your AWS profile name for Account A

  # Alternative: If you prefer to use environment variables instead of profiles,
  # remove the profile line above and set AWS_PROFILE environment variable:
  # export AWS_PROFILE=ACCOUNT_A
  
  # For explicit credentials (not recommended for production):
  # Remove the profile line and uncomment below:
  # access_key = "YOUR_ACCESS_KEY"
  # secret_key = "YOUR_SECRET_KEY"

  default_tags {
    tags = {
      Environment = "prod"
      ManagedBy   = "Terraform"
      Account     = "AccountA"
    }
  }
}

# Provider for Account B (workload account)
# This provider uses the ACCOUNT_B profile from ~/.aws/credentials or ~/.aws/config
# To use a different profile name, modify the profile argument below
provider "aws" {
  alias   = "b"
  region  = var.region_b
  profile = "ACCOUNT_B"  # Change this to match your AWS profile name for Account B

  # Alternative: If you prefer to use environment variables instead of profiles,
  # remove the profile line above and set AWS_PROFILE_B environment variable
  # Note: Terraform doesn't support different AWS_PROFILE per provider alias,
  # so you'll need to use the profile argument or assume role configuration
  
  # For explicit credentials (not recommended for production):
  # Remove the profile line and uncomment below:
  # access_key = "YOUR_ACCESS_KEY"
  # secret_key = "YOUR_SECRET_KEY"

  default_tags {
    tags = {
      Environment = "prod"
      ManagedBy   = "Terraform"
      Account     = "AccountB"
    }
  }
}


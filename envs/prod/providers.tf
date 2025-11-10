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

# Provider for Account A (management account)
# This provider uses the ACCOUNT_A profile from ~/.aws/credentials or ~/.aws/config
#
# Configuration options:
# 1. AWS Profiles (recommended): Set profile = "ACCOUNT_A" and configure in ~/.aws/config:
#    [profile ACCOUNT_A]
#    region = eu-central-1
#    credential_source = Environment
#    # or: aws_access_key_id = ...
#    #     aws_secret_access_key = ...
#
# 2. Environment variables: Remove profile line and set:
#    export AWS_PROFILE=ACCOUNT_A
#    export AWS_REGION=eu-central-1
#
# 3. Explicit credentials (not recommended): Remove profile and uncomment:
#    access_key = var.aws_access_key_id_a  # Define in variables.tf
#    secret_key = var.aws_secret_access_key_a
provider "aws" {
  alias   = "a"
  region  = var.region_a
  profile = "ACCOUNT_A"  # Change this to match your AWS profile name for Account A

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
#
# Configuration options (same as Account A):
# 1. AWS Profiles: Set profile = "ACCOUNT_B" and configure in ~/.aws/config
# 2. Environment variables: Note that Terraform doesn't support different AWS_PROFILE
#    per provider alias, so use the profile argument or assume role configuration
# 3. Explicit credentials: Define variables and use access_key/secret_key
provider "aws" {
  alias   = "b"
  region  = var.region_b
  profile = "ACCOUNT_B"  # Change this to match your AWS profile name for Account B

  default_tags {
    tags = {
      Environment = "prod"
      ManagedBy   = "Terraform"
      Account     = "AccountB"
    }
  }
}


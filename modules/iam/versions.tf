# Terraform and provider version requirements for the IAM module
# This ensures the module uses the correct provider versions and requires explicit provider aliases

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      # Explicitly require provider aliases to prevent accidental use of default provider
      configuration_aliases = [aws.a, aws.b]
    }
  }
}


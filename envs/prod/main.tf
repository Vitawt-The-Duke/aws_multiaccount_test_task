# Main Terraform configuration for production environment
# This file calls the IAM module with environment-specific variables

module "iam" {
  source = "../../modules/iam"

  # Account IDs
  account_a_id = var.account_a_id
  account_b_id = var.account_b_id

  # Regions
  region_a = var.region_a
  region_b = var.region_b

  # Console login configuration
  create_console_login_denys = var.create_console_login_denys
  create_console_login_ivan  = var.create_console_login_ivan

  # Role assumption configuration
  role_b_allowed_assumers = var.role_b_allowed_assumers

  # S3 bucket configuration
  create_s3_bucket = var.create_s3_bucket
  s3_bucket_name   = var.s3_bucket_name

  # Providers are passed implicitly via provider aliases
  # The module uses aws.a and aws.b providers
}

# Outputs from the module
output "engine_access_key_id" {
  description = "Access key ID for engine user"
  value       = module.iam.engine_access_key_id
}

output "ci_access_key_id" {
  description = "Access key ID for ci user"
  value       = module.iam.ci_access_key_id
}

output "denys_platon_initial_password" {
  description = "Initial console password for Denys_Platon"
  value       = module.iam.denys_platon_initial_password
  sensitive   = true
}

output "ivan_petrenko_initial_password" {
  description = "Initial console password for Ivan_Petrenko"
  value       = module.iam.ivan_petrenko_initial_password
  sensitive   = true
}

output "rolea_arn" {
  description = "ARN of roleA in Account A"
  value       = module.iam.rolea_arn
}

output "roleb_arn" {
  description = "ARN of roleB in Account A"
  value       = module.iam.roleb_arn
}

output "rolec_arn" {
  description = "ARN of roleC in Account B"
  value       = module.iam.rolec_arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket in Account B"
  value       = module.iam.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket in Account B"
  value       = module.iam.s3_bucket_arn
}


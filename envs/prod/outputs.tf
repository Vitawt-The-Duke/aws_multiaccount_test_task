# Outputs from the IAM module
# These outputs expose important resource information from the module

output "engine_access_key_id" {
  description = "Access key ID for engine user"
  value       = module.iam.engine_access_key_id
}

output "ci_access_key_id" {
  description = "Access key ID for ci user"
  value       = module.iam.ci_access_key_id
}

output "denys_platon_initial_password" {
  description = "Initial console password for Denys_Platon (temporary, must be changed on first login)"
  value       = module.iam.denys_platon_initial_password
  sensitive   = true
}

output "ivan_petrenko_initial_password" {
  description = "Initial console password for Ivan_Petrenko (temporary, must be changed on first login)"
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

output "denys_platon_access_key_id" {
  description = "Access key ID for Denys_Platon user"
  value       = module.iam.denys_platon_access_key_id
}

output "ivan_petrenko_access_key_id" {
  description = "Access key ID for Ivan_Petrenko user"
  value       = module.iam.ivan_petrenko_access_key_id
}


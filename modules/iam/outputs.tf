# Module outputs
# These outputs expose important resource information to the calling module

# Access key IDs for CLI-only users
# Note: Secret access keys are sensitive and should be retrieved separately
# They are not output here for security reasons
output "engine_access_key_id" {
  description = "Access key ID for engine user"
  value       = aws_iam_access_key.engine.id
  sensitive   = false
}

output "ci_access_key_id" {
  description = "Access key ID for ci user"
  value       = aws_iam_access_key.ci.id
  sensitive   = false
}

# Initial console passwords for full users
# These are sensitive outputs that should be handled carefully
# Passwords are temporary and must be changed on first login
output "denys_platon_initial_password" {
  description = "Initial console password for Denys_Platon (temporary, must be changed on first login)"
  value       = var.create_console_login_denys ? aws_iam_user_login_profile.denys_platon[0].password : null
  sensitive   = true
}

output "ivan_petrenko_initial_password" {
  description = "Initial console password for Ivan_Petrenko (temporary, must be changed on first login)"
  value       = var.create_console_login_ivan ? aws_iam_user_login_profile.ivan_petrenko[0].password : null
  sensitive   = true
}

# Role ARNs
# These are useful for referencing roles in other configurations or documentation
output "rolea_arn" {
  description = "ARN of roleA in Account A"
  value       = aws_iam_role.rolea.arn
}

output "roleb_arn" {
  description = "ARN of roleB in Account A"
  value       = aws_iam_role.roleb.arn
}

output "rolec_arn" {
  description = "ARN of roleC in Account B"
  value       = aws_iam_role.rolec.arn
}

# S3 Bucket information
output "s3_bucket_name" {
  description = "Name of the S3 bucket in Account B"
  value       = var.create_s3_bucket ? aws_s3_bucket.test_bucket[0].id : null
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket in Account B"
  value       = var.create_s3_bucket ? aws_s3_bucket.test_bucket[0].arn : null
}

# Additional useful outputs
output "group1_name" {
  description = "Name of group1 (CLI-only users)"
  value       = aws_iam_group.group1.name
}

output "group2_name" {
  description = "Name of group2 (Full users)"
  value       = aws_iam_group.group2.name
}


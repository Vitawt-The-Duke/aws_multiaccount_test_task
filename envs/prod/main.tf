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

  # PGP key for password encryption
  pgp_key = var.pgp_key

  # Explicitly pass providers to ensure correct account targeting
  # This prevents accidental deployment to the wrong account
  providers = {
    aws.a = aws.a  # Account A (management account)
    aws.b = aws.b  # Account B (workload account)
  }
}


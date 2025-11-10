# Local values for standardizing IAM resource names
# This ensures consistent naming conventions across all resources

locals {
  # Standardize user names: replace spaces with underscores, ensure proper casing
  user_engine        = "engine"
  user_ci           = "ci"
  user_denys        = "Denys_Platon"
  user_ivan         = "Ivan_Petrenko"
  
  # Group names
  group_cli_only    = "group1"
  group_full_users  = "group2"
  
  # Role names
  role_a_name       = "roleA"
  role_b_name       = "roleB"
  role_c_name       = "roleC"
  
  # Policy names
  policy_programmatic_readonly = "ProgrammaticReadOnly"
  policy_mfa_enforcement       = "MFAEnforcementPolicy"
  
  # S3 bucket name
  s3_bucket_name    = var.s3_bucket_name
}


# Environment-level variables for the production environment

variable "account_a_id" {
  description = "AWS Account ID for Account A (management account)"
  type        = string
  default     = "000000000000"
}

variable "account_b_id" {
  description = "AWS Account ID for Account B (workload account)"
  type        = string
  default     = "111111111111"
}

variable "region_a" {
  description = "AWS region for Account A resources"
  type        = string
  default     = "eu-central-1"
}

variable "region_b" {
  description = "AWS region for Account B resources"
  type        = string
  default     = "eu-central-1"
}

variable "create_console_login_denys" {
  description = "Whether to create console login profile for Denys_Platon"
  type        = bool
  default     = true
}

variable "create_console_login_ivan" {
  description = "Whether to create console login profile for Ivan_Petrenko"
  type        = bool
  default     = true
}

variable "role_b_allowed_assumers" {
  description = "List of IAM principal ARNs allowed to assume roleB in Account A"
  type        = list(string)
  default     = []
}

variable "create_s3_bucket" {
  description = "Whether to create the S3 bucket aws-test-bucket in Account B"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to create in Account B"
  type        = string
  default     = "aws-test-bucket"
}

# Backend configuration variables
variable "backend_bucket" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = ""
}

variable "backend_key" {
  description = "S3 key (path) for Terraform remote state"
  type        = string
  default     = "terraform.tfstate"
}

variable "backend_region" {
  description = "AWS region for Terraform remote state backend"
  type        = string
  default     = "eu-central-1"
}

variable "backend_dynamodb_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = ""
}


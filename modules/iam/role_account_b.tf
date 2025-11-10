# IAM Role in Account B (111111111111)
# This role provides S3 access and is assumed from Account A via roleB

# roleC: Service role with S3 access to aws-test-bucket
# This role is assumed by roleB from Account A, enabling cross-account access
# to S3 resources in Account B
# Note: Bucket ARN uses conditional - if bucket is created, use actual bucket ID, otherwise use base name
data "aws_iam_policy_document" "rolec_permissions" {
  provider = aws.b

  # Bucket-level permissions: ListBucket
  # This allows listing objects in the bucket
  statement {
    sid    = "BucketLevel"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = var.create_s3_bucket ? [
      "arn:aws:s3:::${aws_s3_bucket.test_bucket[0].id}"
    ] : [
      "arn:aws:s3:::${var.s3_bucket_name}"
    ]
  }

  # Object-level permissions: Get, Put, Delete, and multipart operations
  # This allows full object operations within the bucket
  statement {
    sid    = "ObjectLevel"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload"
    ]
    resources = var.create_s3_bucket ? [
      "arn:aws:s3:::${aws_s3_bucket.test_bucket[0].id}/*"
    ] : [
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }
}

# Trust policy for roleC
# This allows assumption ONLY by roleB from Account A
# Cross-account role assumption requires:
# 1. The role in Account B (roleC) trusts the role in Account A (roleB)
# 2. The role in Account A (roleB) has permission to assume roleC
# 3. The principal assuming roleB must have permission to assume roleB
# 
# Flow: User/Service → roleB (Account A) → roleC (Account B) → S3 access
#
# CRITICAL: The ARN in this trust policy must EXACTLY match the ARN of roleB
# Any typo or mismatch will cause AccessDenied errors. The ARN format is:
# arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
#
# Note: We use local.role_b_name here, but the ARN must reference roleB in Account A.
# Since roleB is created in Account A, we construct its ARN using account_a_id.
data "aws_iam_policy_document" "rolec_trust" {
  provider = aws.b

  statement {
    sid    = "TrustRoleBFromAccountA"
    effect = "Allow"
    principals {
      type = "AWS"
      # CRITICAL: This ARN must exactly match roleB's ARN in Account A
      # Format: arn:aws:iam::ACCOUNT_A_ID:role/roleB
      # Any mismatch (typo, wrong account ID, wrong role name) will cause AccessDenied
      identifiers = [
        "arn:aws:iam::${var.account_a_id}:role/${local.role_b_name}"
      ]
    }
    actions = ["sts:AssumeRole"]
    # Optional: Add conditions for additional security (e.g., MFA, IP restrictions)
    # Example condition:
    # condition {
    #   test     = "StringEquals"
    #   variable = "sts:ExternalId"
    #   values   = ["unique-external-id"]
    # }
  }
}

resource "aws_iam_role" "rolec" {
  provider           = aws.b
  name               = local.role_c_name
  assume_role_policy = data.aws_iam_policy_document.rolec_trust.json

  tags = {
    Name        = "S3 Access Role"
    Description = "Provides S3 access to aws-test-bucket, assumed from Account A"
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

# Attach the permissions policy to roleC
# Using aws_iam_role_policy instead of deprecated inline_policy block
resource "aws_iam_role_policy" "rolec_permissions" {
  provider = aws.b
  name     = "S3Access"
  role     = aws_iam_role.rolec.id
  policy   = data.aws_iam_policy_document.rolec_permissions.json
}

# Random string for unique bucket name
# S3 bucket names must be globally unique, so we append a random suffix
resource "random_string" "bucket_suffix" {
  count   = var.create_s3_bucket ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket: aws-test-bucket
# This bucket is created in Account B and accessed via roleC
# Bucket creation is optional and controlled by the create_s3_bucket variable
# Bucket name includes random suffix to ensure global uniqueness
resource "aws_s3_bucket" "test_bucket" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b
  bucket   = var.create_s3_bucket ? "${var.s3_bucket_name}-${random_string.bucket_suffix[0].result}" : var.s3_bucket_name

  tags = {
    Name        = "Test Bucket"
    Description = "Bucket for testing cross-account access via roleC"
  }
}

# Enable versioning on the bucket
# Versioning helps with data protection and recovery
resource "aws_s3_bucket_versioning" "test_bucket" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b
  bucket   = aws_s3_bucket.test_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configure bucket ownership controls
# Modern S3 defaults (Object Ownership = BucketOwnerEnforced) disable ACLs
# We need to set ownership to BucketOwnerPreferred to enable ACL usage
# Alternatively, we could omit ACL entirely (bucket is private by default)
resource "aws_s3_bucket_ownership_controls" "test_bucket" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b
  bucket   = aws_s3_bucket.test_bucket[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Set bucket ACL to private
# This ensures the bucket is not publicly accessible
# Access is controlled via IAM policies (roleC) rather than bucket policies
# Note: With modern S3 defaults, ACLs are disabled unless ownership controls are set
resource "aws_s3_bucket_acl" "test_bucket" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b
  bucket   = aws_s3_bucket.test_bucket[0].id
  acl      = "private"

  depends_on = [aws_s3_bucket_ownership_controls.test_bucket]
}

# Block public access to the bucket (defense in depth)
# This provides additional security beyond the bucket policy
resource "aws_s3_bucket_public_access_block" "test_bucket" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b
  bucket   = aws_s3_bucket.test_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption for the bucket
# This ensures all objects are encrypted at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "test_bucket" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b
  bucket   = aws_s3_bucket.test_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Bucket policy (minimal, does not broaden access)
# This policy does not grant additional permissions beyond what roleC provides
# It enforces security best practices: deny public access, deny non-TLS transport
# Only created if bucket is created
data "aws_iam_policy_document" "bucket_policy" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b

  # Deny all public access (defense in depth)
  statement {
    sid    = "DenyPublicAccess"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.test_bucket[0].id}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"
      values   = [var.account_b_id]
    }
  }

  # Deny insecure (non-TLS) transport
  # This ensures all S3 operations must use HTTPS/TLS
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.test_bucket[0].id}",
      "arn:aws:s3:::${aws_s3_bucket.test_bucket[0].id}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "test_bucket" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b
  bucket   = aws_s3_bucket.test_bucket[0].id
  policy    = data.aws_iam_policy_document.bucket_policy[0].json
}


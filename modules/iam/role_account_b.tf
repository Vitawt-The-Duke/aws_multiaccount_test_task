# IAM Role in Account B (111111111111)
# This role provides S3 access and is assumed from Account A via roleB

# roleC: Service role with S3 access to aws-test-bucket
# This role is assumed by roleB from Account A, enabling cross-account access
# to S3 resources in Account B
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
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}"
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
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}/*"
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

  # Attach the permissions policy as an inline policy
  inline_policy {
    name   = "S3Access"
    policy = data.aws_iam_policy_document.rolec_permissions.json
  }

  tags = {
    Name        = "S3 Access Role"
    Description = "Provides S3 access to aws-test-bucket, assumed from Account A"
  }
}

# S3 Bucket: aws-test-bucket
# This bucket is created in Account B and accessed via roleC
# Bucket creation is optional and controlled by the create_s3_bucket variable
resource "aws_s3_bucket" "test_bucket" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b
  bucket   = local.s3_bucket_name

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

# Set bucket ACL to private
# This ensures the bucket is not publicly accessible
# Access is controlled via IAM policies (roleC) rather than bucket policies
resource "aws_s3_bucket_acl" "test_bucket" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b
  bucket   = aws_s3_bucket.test_bucket[0].id
  acl      = "private"
}

# Bucket policy (minimal, does not broaden access)
# This policy does not grant additional permissions beyond what roleC provides
# It's included for completeness and can be used for additional restrictions if needed
data "aws_iam_policy_document" "bucket_policy" {
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
      "arn:aws:s3:::${local.s3_bucket_name}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"
      values   = [var.account_b_id]
    }
  }
}

resource "aws_s3_bucket_policy" "test_bucket" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.b
  bucket   = aws_s3_bucket.test_bucket[0].id
  policy    = data.aws_iam_policy_document.bucket_policy.json
}


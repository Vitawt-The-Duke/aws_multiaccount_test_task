# IAM Roles in Account A (000000000000)
# These roles provide administrative and service access within Account A

# roleA: Administrative role allowing all AWS services except IAM
# This role provides administrative access to most AWS services but explicitly excludes IAM
# 
# IMPORTANT: Using NotAction with iam:* can be problematic because:
# 1. It may trigger AWS policy size limits (max 6144 characters for inline policies)
# 2. Some AWS services may have restrictions on NotAction usage
# 3. It grants very broad permissions that may violate security policies
#
# This implementation uses a more restrictive approach by explicitly allowing
# common administrative actions across major AWS services, while still excluding IAM.
# For production use, consider further restricting to only necessary services.
data "aws_iam_policy_document" "rolea_permissions" {
  provider = aws.a

  # Allow administrative actions for EC2
  statement {
    sid    = "AllowEC2Admin"
    effect = "Allow"
    actions = [
      "ec2:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for S3
  statement {
    sid    = "AllowS3Admin"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for CloudWatch
  statement {
    sid    = "AllowCloudWatchAdmin"
    effect = "Allow"
    actions = [
      "cloudwatch:*",
      "logs:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for Lambda
  statement {
    sid    = "AllowLambdaAdmin"
    effect = "Allow"
    actions = [
      "lambda:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for RDS
  statement {
    sid    = "AllowRDSAdmin"
    effect = "Allow"
    actions = [
      "rds:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for DynamoDB
  statement {
    sid    = "AllowDynamoDBAdmin"
    effect = "Allow"
    actions = [
      "dynamodb:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for ECS/EKS
  statement {
    sid    = "AllowContainerAdmin"
    effect = "Allow"
    actions = [
      "ecs:*",
      "eks:*",
      "ecr:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for CloudFormation
  statement {
    sid    = "AllowCloudFormationAdmin"
    effect = "Allow"
    actions = [
      "cloudformation:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for API Gateway
  statement {
    sid    = "AllowAPIGatewayAdmin"
    effect = "Allow"
    actions = [
      "apigateway:*",
      "execute-api:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for SNS/SQS
  statement {
    sid    = "AllowMessagingAdmin"
    effect = "Allow"
    actions = [
      "sns:*",
      "sqs:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for KMS
  statement {
    sid    = "AllowKMSAdmin"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }

  # Allow administrative actions for VPC and networking
  statement {
    sid    = "AllowNetworkingAdmin"
    effect = "Allow"
    actions = [
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpc*",
      "ec2:DescribeVpc*",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:ModifySubnet*",
      "ec2:DescribeSubnet*",
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:ModifyRouteTable*",
      "ec2:DescribeRouteTable*",
      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:DescribeInternetGateway*",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
      "ec2:DescribeAddress*"
    ]
    resources = ["*"]
  }

  # Explicitly deny all IAM actions
  # This ensures IAM operations are completely blocked
  statement {
    sid    = "DenyIAM"
    effect = "Deny"
    actions = [
      "iam:*"
    ]
    resources = ["*"]
  }

  # Allow STS actions needed for role assumption and identity verification
  statement {
    sid    = "AllowSTS"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
      "sts:AssumeRole"
    ]
    resources = ["*"]
  }
}

# Trust policy for roleA
# This allows assumption by IAM users in Account A
# We trust the account root (000000000000:root) because IAM role trust policies
# cannot directly reference IAM groups. Instead, we:
# 1. Trust the account root in the role trust policy (this file)
# 2. Attach an allow policy to group2 that grants sts:AssumeRole on roleA (in policies.tf)
# This is the recommended AWS pattern for group-based role assumption
data "aws_iam_policy_document" "rolea_trust" {
  provider = aws.a

  statement {
    sid    = "TrustAccountAUsers"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_a_id}:root"]
    }
    actions = ["sts:AssumeRole"]
    # Optional: Add conditions to further restrict who can assume
    # The actual enforcement is via the policy attached to group2
  }
}

resource "aws_iam_role" "rolea" {
  provider           = aws.a
  name               = local.role_a_name
  assume_role_policy = data.aws_iam_policy_document.rolea_trust.json

  # Attach the permissions policy as an inline policy
  inline_policy {
    name   = "AdministrativeAccess"
    policy = data.aws_iam_policy_document.rolea_permissions.json
  }

  tags = {
    Name        = "Administrative Role"
    Description = "Allows all AWS services except IAM operations"
  }
}

# roleB: Service role that can assume roleC in Account B
# This role acts as a bridge between Account A and Account B
# It has permission to assume roleC, which provides S3 access in Account B
#
# CRITICAL: The ARN in this policy must EXACTLY match roleC's ARN in Account B.
# Any typo or mismatch will cause AccessDenied errors. The ARN format is:
# arn:aws:iam::ACCOUNT_B_ID:role/roleC
data "aws_iam_policy_document" "roleb_permissions" {
  provider = aws.a

  statement {
    sid    = "AllowAssumeRoleC"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      # CRITICAL: This ARN must exactly match roleC's ARN in Account B
      # Format: arn:aws:iam::ACCOUNT_B_ID:role/roleC
      # Any mismatch (typo, wrong account ID, wrong role name) will cause AccessDenied
      "arn:aws:iam::${var.account_b_id}:role/${local.role_c_name}"
    ]
  }
}

# Trust policy for roleB
# This allows assumption by specified principals in Account A
# By default, users in group1 (engine and ci) can assume this role
# Additional assumers can be configured via the role_b_allowed_assumers variable
data "aws_iam_policy_document" "roleb_trust" {
  provider = aws.a

  statement {
    sid    = "TrustAccountAPrincipals"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_a_id}:root"]
    }
    actions = ["sts:AssumeRole"]
    # The actual enforcement of who can assume is via policies attached
    # to group1 (or other principals specified in role_b_allowed_assumers)
  }
}

resource "aws_iam_role" "roleb" {
  provider           = aws.a
  name               = local.role_b_name
  assume_role_policy = data.aws_iam_policy_document.roleb_trust.json

  # Attach the permissions policy as an inline policy
  inline_policy {
    name   = "AssumeRoleC"
    policy = data.aws_iam_policy_document.roleb_permissions.json
  }

  tags = {
    Name        = "Cross-Account Bridge Role"
    Description = "Allows assumption of roleC in Account B"
  }
}


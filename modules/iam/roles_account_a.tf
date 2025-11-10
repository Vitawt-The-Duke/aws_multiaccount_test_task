# IAM Roles in Account A (000000000000)
# These roles provide administrative and service access within Account A

# roleA: Administrative role allowing all AWS services except IAM
# This role uses NotAction to allow everything except IAM operations
# NotAction is useful here because it's more maintainable than listing all possible
# AWS service actions and explicitly denying IAM. Any new AWS service will automatically
# be included in the allowed actions, but IAM operations remain restricted.
data "aws_iam_policy_document" "rolea_permissions" {
  provider = aws.a

  statement {
    sid    = "AllowAllExceptIAM"
    effect = "Allow"
    # NotAction means "allow everything except these actions"
    # This is more maintainable than listing all AWS service actions
    not_actions = ["iam:*"]
    resources    = ["*"]
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
data "aws_iam_policy_document" "roleb_permissions" {
  provider = aws.a

  statement {
    sid    = "AllowAssumeRoleC"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
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


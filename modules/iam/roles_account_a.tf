# IAM Roles in Account A (000000000000)
# These roles provide administrative and service access within Account A

# roleA: Administrative role allowing all AWS services except IAM
# This role uses NotAction to allow everything except IAM operations
# 
# RATIONALE: Using NotAction: iam:* is the canonical way to grant "all services except IAM"
# as required. While this grants very broad permissions, it's acceptable here because:
# 1. This is an administrative role intended for power users (group2)
# 2. The role explicitly excludes IAM operations, preventing privilege escalation
# 3. Access is controlled via group membership and MFA enforcement
# 4. The alternative (explicit allow-list) would be incomplete and harder to maintain
#
# RISKS: This grants access to ALL AWS services except IAM, which may violate some
# security policies. For production use, consider:
# - Using AWS managed policies (e.g., PowerUserAccess) instead
# - Further restricting to only necessary services
# - Implementing additional conditions (e.g., IP restrictions, time-based access)
data "aws_iam_policy_document" "rolea_permissions" {
  provider = aws.a

  # Allow all actions except IAM
  # NotAction means "allow everything except these actions"
  # This is the canonical way to grant "all services except IAM"
  statement {
    sid    = "AllowAllExceptIAM"
    effect = "Allow"
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

  tags = {
    Name        = "Administrative Role"
    Description = "Allows all AWS services except IAM operations"
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

# Attach the permissions policy to roleA
# Using aws_iam_role_policy instead of deprecated inline_policy block
resource "aws_iam_role_policy" "rolea_permissions" {
  provider = aws.a
  name     = "AdministrativeAccess"
  role     = aws_iam_role.rolea.id
  policy   = data.aws_iam_policy_document.rolea_permissions.json
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
      type = "AWS"
      # Trust account root (for group-based access) and any additional principals
      # specified via role_b_allowed_assumers variable
      identifiers = concat(
        ["arn:aws:iam::${var.account_a_id}:root"],
        var.role_b_allowed_assumers
      )
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

  tags = {
    Name        = "Cross-Account Bridge Role"
    Description = "Allows assumption of roleC in Account B"
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

# Attach the permissions policy to roleB
# Using aws_iam_role_policy instead of deprecated inline_policy block
resource "aws_iam_role_policy" "roleb_permissions" {
  provider = aws.a
  name     = "AssumeRoleC"
  role     = aws_iam_role.roleb.id
  policy   = data.aws_iam_policy_document.roleb_permissions.json
}


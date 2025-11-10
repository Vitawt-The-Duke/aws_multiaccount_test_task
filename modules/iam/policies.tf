# IAM Policies for Account A
# Custom managed policies and policy documents for various use cases

# Attach AWS managed ReadOnlyAccess to group1 (CLI-only users)
# This provides comprehensive read-only access to all AWS services
# Using AWS managed policy avoids policy size limits and maintenance burden
resource "aws_iam_group_policy_attachment" "group1_readonly_managed" {
  provider   = aws.a
  group      = aws_iam_group.group1.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Deny AssumeRole policy (except for roleB)
# This policy denies sts:AssumeRole on all roles except roleB
# CRITICAL: We use NotResource to carve out an exception for roleB
# Without this exception, the explicit Deny would override the Allow policy
# that grants sts:AssumeRole on roleB, preventing group1 users from assuming it
data "aws_iam_policy_document" "deny_assume_role_except_roleb" {
  provider = aws.a

  statement {
    sid    = "DenyAssumeRoleExceptRoleB"
    effect = "Deny"
    actions = [
      "sts:AssumeRole"
    ]
    # Deny AssumeRole on all resources EXCEPT roleB
    # This allows the explicit Allow policy for roleB to work
    not_resources = [
      "arn:aws:iam::${var.account_a_id}:role/${local.role_b_name}"
    ]
  }
}

resource "aws_iam_policy" "deny_assume_role_except_roleb" {
  provider    = aws.a
  name        = "DenyAssumeRoleExceptRoleB"
  description = "Denies sts:AssumeRole on all roles except roleB"
  policy      = data.aws_iam_policy_document.deny_assume_role_except_roleb.json

  tags = {
    Name = "DenyAssumeRoleExceptRoleB"
  }
}

# Attach DenyAssumeRoleExceptRoleB policy to group1
resource "aws_iam_group_policy_attachment" "group1_deny_assume" {
  provider   = aws.a
  group      = aws_iam_group.group1.name
  policy_arn = aws_iam_policy.deny_assume_role_except_roleb.arn
}

# MFA Enforcement Policy
# This policy enforces MFA for all actions except those needed to set up MFA
# It uses a Deny effect with a condition that checks if MFA is not present
# This ensures that users in group2 (full users) must use MFA for all operations
data "aws_iam_policy_document" "mfa_enforcement" {
  provider = aws.a

  # Allow actions needed to set up and manage MFA without MFA being present
  # This is essential so users can enroll their MFA device on first login
  statement {
    sid    = "AllowMFASetup"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }

  # Deny all actions if MFA is not present
  # The condition checks if aws:MultiFactorAuthPresent is false or doesn't exist
  # Using BoolIfExists with "false" means: deny if MFA is explicitly false OR if the key doesn't exist
  # This ensures that all actions (except MFA setup) require MFA authentication
  statement {
    sid    = "DenyAllWithoutMFA"
    effect = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
    # Condition: Deny if MFA is not present
    # BoolIfExists returns true if the key exists and is true, false otherwise
    # So we deny when the value is false or the key doesn't exist
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "mfa_enforcement" {
  provider    = aws.a
  name        = local.policy_mfa_enforcement
  description = "Enforces MFA for all actions except MFA setup operations"
  policy      = data.aws_iam_policy_document.mfa_enforcement.json

  tags = {
    Name = "MFAEnforcementPolicy"
  }
}

# Attach MFA enforcement policy to group2 (full users)
resource "aws_iam_group_policy_attachment" "group2_mfa" {
  provider   = aws.a
  group      = aws_iam_group.group2.name
  policy_arn = aws_iam_policy.mfa_enforcement.arn
}

# Attach AWS managed PowerUserAccess to group2
# PowerUserAccess provides full access to AWS services except IAM management
resource "aws_iam_group_policy_attachment" "group2_poweruser" {
  provider   = aws.a
  group      = aws_iam_group.group2.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Policy to allow group2 members to assume roleA
# This policy is attached to group2 and grants sts:AssumeRole permission on roleA
# Note: The role trust policy trusts the account root, but this policy on the group
# provides the actual permission to assume the role. This is the recommended pattern
# because IAM role trust policies cannot directly reference IAM groups.
data "aws_iam_policy_document" "group2_assume_rolea" {
  provider = aws.a

  statement {
    sid    = "AllowAssumeRoleA"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.account_a_id}:role/${local.role_a_name}"
    ]
  }
}

resource "aws_iam_policy" "group2_assume_rolea" {
  provider    = aws.a
  name        = "Group2AssumeRoleA"
  description = "Allows group2 members to assume roleA"
  policy      = data.aws_iam_policy_document.group2_assume_rolea.json
}

resource "aws_iam_group_policy_attachment" "group2_assume_rolea" {
  provider   = aws.a
  group      = aws_iam_group.group2.name
  policy_arn = aws_iam_policy.group2_assume_rolea.arn
}

# Policy to allow group1 members (or specified assumers) to assume roleB
# This policy can be attached to group1 or individual users/roles
# The list of allowed assumers is configurable via variable
data "aws_iam_policy_document" "assume_roleb" {
  provider = aws.a

  statement {
    sid    = "AllowAssumeRoleB"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.account_a_id}:role/${local.role_b_name}"
    ]
  }
}

resource "aws_iam_policy" "assume_roleb" {
  provider    = aws.a
  name        = "AssumeRoleB"
  description = "Allows specified principals to assume roleB"
  policy      = data.aws_iam_policy_document.assume_roleb.json
}

# Attach assume roleB policy to group1
resource "aws_iam_group_policy_attachment" "group1_assume_roleb" {
  provider   = aws.a
  group      = aws_iam_group.group1.name
  policy_arn = aws_iam_policy.assume_roleb.arn
}


# IAM Groups for Account A
# Groups organize users and simplify permission management

# Group 1: CLI-only users
# This group is for users who only need programmatic access (access keys)
# and should NOT have console login capabilities
resource "aws_iam_group" "group1" {
  provider = aws.a
  name     = local.group_cli_only
  path     = "/"
  # Note: aws_iam_group does not support tags directly
}

# Group 2: Full users
# This group is for users who need both console and programmatic access
# Console access requires MFA enforcement via attached policy
resource "aws_iam_group" "group2" {
  provider = aws.a
  name     = local.group_full_users
  path     = "/"
  # Note: aws_iam_group does not support tags directly
}


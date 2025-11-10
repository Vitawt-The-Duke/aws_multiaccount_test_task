# IAM Groups for Account A
# Groups organize users and simplify permission management

# Group 1: CLI-only users
# This group is for users who only need programmatic access (access keys)
# and should NOT have console login capabilities
resource "aws_iam_group" "group1" {
  provider = aws.a
  name     = local.group_cli_only
  path     = "/"

  tags = {
    Name        = "CLI-only users"
    Description = "Users with programmatic access only, no console login"
  }
}

# Group 2: Full users
# This group is for users who need both console and programmatic access
# Console access requires MFA enforcement via attached policy
resource "aws_iam_group" "group2" {
  provider = aws.a
  name     = local.group_full_users
  path     = "/"

  tags = {
    Name        = "Full users"
    Description = "Users with console and programmatic access, MFA required"
  }
}


# IAM Users for Account A
# Users are organized into groups for permission management

# CLI-only users: engine and ci
# These users only have programmatic access (access keys)
# No console login profiles are created for them

resource "aws_iam_user" "engine" {
  provider = aws.a
  name     = local.user_engine
  path     = "/"

  tags = {
    Name        = "Engine User"
    Description = "CLI-only user for engine operations"
    Type        = "CLI-only"
  }
}

resource "aws_iam_user" "ci" {
  provider = aws.a
  name     = local.user_ci
  path     = "/"

  tags = {
    Name        = "CI User"
    Description = "CLI-only user for CI/CD operations"
    Type        = "CLI-only"
  }
}

# Full users: Denys_Platon and Ivan_Petrenko
# These users have both console and programmatic access
# Console login profiles are created with temporary passwords

resource "aws_iam_user" "denys_platon" {
  provider = aws.a
  name     = local.user_denys
  path     = "/"

  tags = {
    Name        = "Denys Platon"
    Description = "Full user with console and programmatic access"
    Type        = "Full"
  }
}

resource "aws_iam_user" "ivan_petrenko" {
  provider = aws.a
  name     = local.user_ivan
  path     = "/"

  tags = {
    Name        = "Ivan Petrenko"
    Description = "Full user with console and programmatic access"
    Type        = "Full"
  }
}

# Group memberships
# Add CLI-only users to group1

resource "aws_iam_user_group_membership" "engine_group1" {
  provider = aws.a
  user     = aws_iam_user.engine.name
  groups   = [aws_iam_group.group1.name]
}

resource "aws_iam_user_group_membership" "ci_group1" {
  provider = aws.a
  user     = aws_iam_user.ci.name
  groups   = [aws_iam_group.group1.name]
}

# Add full users to group2

resource "aws_iam_user_group_membership" "denys_group2" {
  provider = aws.a
  user     = aws_iam_user.denys_platon.name
  groups   = [aws_iam_group.group2.name]
}

resource "aws_iam_user_group_membership" "ivan_group2" {
  provider = aws.a
  user     = aws_iam_user.ivan_petrenko.name
  groups   = [aws_iam_group.group2.name]
}

# Access keys for CLI-only users
# These are the only credentials created for CLI-only users

resource "aws_iam_access_key" "engine" {
  provider = aws.a
  user     = aws_iam_user.engine.name
}

resource "aws_iam_access_key" "ci" {
  provider = aws.a
  user     = aws_iam_user.ci.name
}

# Console login profiles for full users
# These create temporary passwords that must be changed on first login
# Only create if the corresponding variable is true

resource "aws_iam_user_login_profile" "denys_platon" {
  count                   = var.create_console_login_denys ? 1 : 0
  provider                = aws.a
  user                    = aws_iam_user.denys_platon.name
  password_length         = 20
  password_reset_required = true
}

resource "aws_iam_user_login_profile" "ivan_petrenko" {
  count                   = var.create_console_login_ivan ? 1 : 0
  provider                = aws.a
  user                    = aws_iam_user.ivan_petrenko.name
  password_length         = 20
  password_reset_required = true
}


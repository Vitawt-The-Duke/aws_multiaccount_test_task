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

  lifecycle {
    prevent_destroy = var.prevent_destroy
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

  lifecycle {
    prevent_destroy = var.prevent_destroy
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

  lifecycle {
    prevent_destroy = var.prevent_destroy
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

  lifecycle {
    prevent_destroy = var.prevent_destroy
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

# Access keys for full users (group2)
# These users have both console and programmatic access
# Access keys enable programmatic access for automation and CLI usage

resource "aws_iam_access_key" "denys_platon" {
  provider = aws.a
  user     = aws_iam_user.denys_platon.name
}

resource "aws_iam_access_key" "ivan_petrenko" {
  provider = aws.a
  user     = aws_iam_user.ivan_petrenko.name
}

# Console login profiles for full users
# These create temporary passwords that must be changed on first login
# Only create if the corresponding variable is true
#
# SECURITY: If pgp_key is provided, passwords are encrypted and stored as encrypted_password.
# If pgp_key is not provided, passwords are stored in plaintext in Terraform state (not recommended).
# Options for pgp_key:
# - Base64-encoded PGP public key
# - "keybase:username" (uses Keybase public key)
# - "file://path/to/key.pub" (reads from file)
#
# WARNING: Initial passwords are only available once during creation.
# If the password is not retrieved immediately and pgp_key is not set, it cannot be recovered.
# Users must change their password on first login, and if they fail to do so,
# the password may expire and require manual reset via AWS Console or CLI.
#
# Lifecycle management:
# - Ignore changes to password after initial creation to prevent unnecessary updates
# - This prevents Terraform from trying to recreate the login profile

resource "aws_iam_user_login_profile" "denys_platon" {
  count                   = var.create_console_login_denys ? 1 : 0
  provider                = aws.a
  user                    = aws_iam_user.denys_platon.name
  password_length         = 20
  password_reset_required = true
  pgp_key                 = var.pgp_key != "" ? var.pgp_key : null

  lifecycle {
    # Ignore password changes after creation
    # The password is only available during initial creation
    ignore_changes = [password_length, password_reset_required, pgp_key]
  }
}

resource "aws_iam_user_login_profile" "ivan_petrenko" {
  count                   = var.create_console_login_ivan ? 1 : 0
  provider                = aws.a
  user                    = aws_iam_user.ivan_petrenko.name
  password_length         = 20
  password_reset_required = true
  pgp_key                 = var.pgp_key != "" ? var.pgp_key : null

  lifecycle {
    # Ignore password changes after creation
    # The password is only available during initial creation
    ignore_changes = [password_length, password_reset_required, pgp_key]
  }
}


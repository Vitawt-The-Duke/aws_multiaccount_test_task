# AWS Multi-Account IAM Setup with Terraform

This Terraform project implements a comprehensive multi-account IAM setup across two AWS accounts with three distinct stages of access control.

## Project Overview

This project creates IAM resources across two AWS accounts:

- **Account A (Management)**: `000000000000` - Contains IAM groups, users, and roles
- **Account B (Workload)**: `111111111111` - Contains a service role and S3 bucket for cross-account access

## Architecture

### Stage 1: Groups and Users in Account A

- **group1** (CLI-only users): Users with programmatic access only
  - Users: `engine`, `ci`
  - Policy: Read-only access with explicit `sts:AssumeRole` denial
  - No console login profiles

- **group2** (Full users): Users with console and programmatic access
  - Users: `Denys_Platon`, `Ivan_Petrenko`
  - Policies: PowerUserAccess + MFA enforcement
  - Console login profiles with temporary passwords

### Stage 2: Roles in Account A

- **roleA**: Administrative role allowing all AWS services except IAM
  - Assumed by: group2 members
  - Uses `NotAction: iam:*` for maintainability

- **roleB**: Service role that can assume roleC in Account B
  - Assumed by: group1 members (engine, ci)
  - Permissions: `sts:AssumeRole` on roleC

### Stage 3: Role in Account B

- **roleC**: Service role with S3 access to `aws-test-bucket`
  - Assumed by: roleB from Account A
  - Permissions: Full S3 operations on the test bucket

- **aws-test-bucket**: S3 bucket with versioning enabled and private ACL

## Prerequisites

- Terraform >= 1.6
- AWS Provider >= 5.0
- AWS CLI configured with profiles for both accounts
- Appropriate IAM permissions in both accounts

## Project Structure

```
.
├── modules/
│   └── iam/
│       ├── variables.tf          # Module input variables
│       ├── locals.tf             # Local values for naming
│       ├── groups.tf             # IAM groups
│       ├── users.tf             # IAM users and memberships
│       ├── policies.tf          # IAM policies and attachments
│       ├── roles_account_a.tf   # Roles in Account A
│       ├── role_account_b.tf    # Role and S3 bucket in Account B
│       └── outputs.tf           # Module outputs
├── envs/
│   └── prod/
│       ├── main.tf              # Module instantiation
│       ├── providers.tf        # AWS provider configuration
│       ├── backend.tf          # Remote state backend config
│       ├── variables.tf        # Environment variables
│       └── terraform.tfvars.example  # Example variable values
├── README.md                   # This file
└── Makefile                    # Makefile with common commands
```

## Setup Instructions

### 1. Configure AWS Profiles

Set up AWS profiles in `~/.aws/credentials`:

```ini
[profile ACCOUNT_A]
aws_access_key_id = YOUR_ACCOUNT_A_ACCESS_KEY
aws_secret_access_key = YOUR_ACCOUNT_A_SECRET_KEY
region = eu-central-1

[profile ACCOUNT_B]
aws_access_key_id = YOUR_ACCOUNT_B_ACCESS_KEY
aws_secret_access_key = YOUR_ACCOUNT_B_SECRET_KEY
region = eu-central-1
```

Alternatively, configure in `~/.aws/config`:

```ini
[profile ACCOUNT_A]
region = eu-central-1
credential_source = Environment
# or use: role_arn = arn:aws:iam::000000000000:role/YourRole

[profile ACCOUNT_B]
region = eu-central-1
credential_source = Environment
```

### 2. Configure Backend (Optional but Recommended)

The project uses S3 + DynamoDB for remote state. Create a `backend.hcl` file in `envs/prod/`:

```hcl
bucket         = "your-terraform-state-bucket"
key            = "prod/iam/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
```

Or use `-backend-config` flags during initialization.

### 3. Configure Variables

Copy the example variables file and customize:

```bash
cd envs/prod
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your actual account IDs and configuration:

```hcl
account_a_id = "000000000000"  # Your actual Account A ID
account_b_id = "111111111111"  # Your actual Account B ID
region_a     = "eu-central-1"
region_b     = "eu-central-1"
```

### 4. Initialize Terraform

```bash
# Using Makefile (recommended)
make init

# Or manually
cd envs/prod
terraform init

# With backend configuration
make init-backend
# Or: terraform init -backend-config=backend.hcl
```

### 5. Plan and Apply

```bash
# Review changes
make plan

# Apply changes
make apply

# Or auto-approve (use with caution)
make apply-auto
```

## Usage

### Using the Makefile

The Makefile provides convenient targets for common operations:

```bash
make help          # Show all available targets
make init          # Initialize Terraform
make plan          # Show execution plan
make apply         # Apply changes (with confirmation)
make apply-auto    # Apply changes (auto-approve)
make destroy       # Destroy all resources
make output        # Show outputs
make validate      # Validate configuration
make fmt           # Format Terraform files
```

### Custom Profile Names

You can override the default profile names:

```bash
make plan ACCOUNT_A_PROFILE=my-profile-a ACCOUNT_B_PROFILE=my-profile-b
make apply ACCOUNT_A_PROFILE=my-profile-a ACCOUNT_B_PROFILE=my-profile-b
```

### Manual Terraform Commands

If you prefer using Terraform directly:

```bash
cd envs/prod

# Set AWS profiles via environment variables
export AWS_PROFILE=ACCOUNT_A
export AWS_PROFILE_B=ACCOUNT_B  # Note: Terraform providers use different methods

# Or use -var flags
terraform plan \
  -var="account_a_id=000000000000" \
  -var="account_b_id=111111111111"
```

**Important**: The providers are configured to use AWS profiles. Ensure your `~/.aws/credentials` or `~/.aws/config` is properly set up.

## Key Design Decisions

### Why Trust Account Root but Enforce via Group Policies?

IAM role trust policies cannot directly reference IAM groups. The recommended pattern is:

1. **Trust Policy**: Trust the account root (`arn:aws:iam::ACCOUNT:root`)
2. **Permission Policy**: Attach an allow policy to the group granting `sts:AssumeRole` on the specific role

This provides:
- Flexibility to add/remove users from groups without modifying role trust policies
- Clear separation of concerns (trust vs. permissions)
- Easier auditing (group membership changes don't require role updates)

### Why NotAction: iam:* in roleA?

Using `NotAction: iam:*` instead of listing all AWS service actions:

- **Maintainability**: New AWS services are automatically included
- **Simplicity**: One statement instead of hundreds
- **Clarity**: Explicitly shows IAM is excluded

The alternative would require maintaining a comprehensive list of all AWS service actions, which is impractical.

### Cross-Account Trust Flow

The cross-account role assumption works as follows:

1. **User/Service** in Account A assumes **roleB** (requires permission via group1 policy)
2. **roleB** assumes **roleC** in Account B (requires permission in roleB's policy + trust in roleC)
3. **roleC** accesses S3 resources in Account B

This creates a secure chain: User → roleB → roleC → S3

## Outputs

After applying, you can retrieve outputs:

```bash
make output

# Or for JSON format
make output-json

# Or manually
cd envs/prod
terraform output
terraform output -json
```

**Important**: Sensitive outputs (passwords, secret keys) are marked as sensitive and won't be displayed by default. Use `terraform output -json` to retrieve them programmatically.

### Key Outputs

- `engine_access_key_id`: Access key ID for engine user
- `ci_access_key_id`: Access key ID for ci user
- `denys_platon_initial_password`: Initial console password (sensitive)
- `ivan_petrenko_initial_password`: Initial console password (sensitive)
- `rolea_arn`, `roleb_arn`, `rolec_arn`: Role ARNs
- `s3_bucket_name`, `s3_bucket_arn`: S3 bucket information

## Security Considerations

1. **MFA Enforcement**: Console users (group2) must use MFA for all operations except MFA setup
2. **Least Privilege**: CLI-only users have read-only access with explicit AssumeRole denial
3. **Cross-Account Security**: roleC only trusts roleB, creating a controlled access path
4. **S3 Bucket**: Private ACL with IAM-based access control (no public access)
5. **State Security**: Use encrypted S3 backend with DynamoDB locking

## Troubleshooting

### Provider Authentication Issues

If you see authentication errors:

1. Verify AWS profiles are configured: `aws configure list --profile ACCOUNT_A`
2. Test profile access: `aws sts get-caller-identity --profile ACCOUNT_A`
3. Check provider configuration in `envs/prod/providers.tf`

### Backend Initialization Issues

If backend initialization fails:

1. Ensure the S3 bucket exists and is accessible
2. Ensure the DynamoDB table exists
3. Check IAM permissions for backend access
4. Use `-backend-config` flags if variables aren't working

### Cross-Account Role Assumption Issues

If role assumption fails:

1. Verify roleB has permission to assume roleC (check inline policy)
2. Verify roleC trusts roleB (check trust policy)
3. Verify the assuming principal has permission to assume roleB
4. Check CloudTrail logs for detailed error messages

## Cleanup

To destroy all resources:

```bash
make destroy
```

**Warning**: This will permanently delete all IAM resources, including users, groups, roles, and the S3 bucket. Ensure you have backups if needed.

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Cross-Account Role Assumption](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_common-scenarios_aws-accounts.html)

## License

This project is provided as-is for demonstration purposes.


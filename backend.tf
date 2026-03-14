# backend.tf
# =============================================================================
# Remote State Backend Configuration
#
# CRITICAL: This must be configured before ANY team member or CI system runs
# terraform init. The S3 bucket and DynamoDB table must already exist before
# you can use this backend — you will create them in Step 2.
#
# Why remote state?
# - Shared: All developers and GitHub Actions use the same state
# - Locked: DynamoDB prevents two simultaneous applies from corrupting state
# - Safe: S3 versioning means you can roll back to a previous state file
# - Encrypted: State can contain sensitive values — SSE protects them at rest
# =============================================================================

terraform {
  backend "s3" {
    # The S3 bucket name — created in Step 2
    # Naming convention: terraform-state-<account_id>-<region>
    bucket = "terraform-state-536300833332-us-east-2"

    # Path within the bucket where the state file is stored.
    # Using a key like this allows multiple projects/environments
    # to share the same bucket with different state files.
    key = "cicd-demo/dev/terraform.tfstate"

    region = "us-east-2"

    # DynamoDB table for state locking — created in Step 2.
    # When a terraform plan or apply starts, it writes a lock entry to this
    # table. Any other Terraform run that tries to start will see the lock
    # and wait (or fail with an informative error). This prevents two
    # simultaneous applies from corrupting the state file.
    dynamodb_table = "terraform-state-lock"

    # Encrypt the state file at rest using AWS-managed keys.
    encrypt = true
  }
}

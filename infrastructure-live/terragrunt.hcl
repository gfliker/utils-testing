# Root terragrunt.hcl
# This file configures settings that are common across all environments

# Include global configuration
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"))
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "my-terraform-state-bucket"  # Change this to your S3 bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    # Using S3 native locking - no DynamoDB table needed
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  
  # Default tags applied to all resources
  default_tags {
    tags = merge(
      local.global_vars.locals.common_tags,
      local.account_vars.locals.common_tags,
      local.region_vars.locals.common_tags,
      {
        Region = var.aws_region
        ManagedBy = "terraform"
      }
    )
  }
}
EOF
}

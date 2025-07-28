include "root" {
  path = find_in_parent_folders()
}

include "global" {
  path = find_in_parent_folders("global.hcl")
}

include "account" {
  path = find_in_parent_folders("account.hcl")
}

include "region" {
  path = find_in_parent_folders("region.hcl")
}

include "category" {
  path = find_in_parent_folders("category.hcl")
}

terraform {
  source = "../../../../../modules/atlantis"
}

# Merge all local variables from includes
locals {
  global_vars   = include.global.locals
  account_vars  = include.account.locals
  region_vars   = include.region.locals
  category_vars = include.category.locals
  
  # Combine all tags
  common_tags = merge(
    local.global_vars.common_tags,
    local.account_vars.account_tags,
    local.region_vars.region_tags,
    local.category_vars.category_tags,
    {
      Service = "atlantis"
      Name    = "${local.global_vars.name_prefix}-atlantis-${local.account_vars.environment}-${local.region_vars.aws_region}"
    }
  )
}

inputs = {
  # Pass through hierarchical variables
  aws_region    = local.region_vars.aws_region
  environment   = local.account_vars.environment
  project_name  = "${local.global_vars.project_name}-${local.account_vars.environment}"
  
  # VPC and Networking (provide existing resources for PRD US-EAST-1)
  vpc_id              = "vpc-prd-us-east-1"  # Replace with your prd us-east-1 VPC ID
  public_subnet_ids   = ["subnet-prd-us-east-1-pub-a", "subnet-prd-us-east-1-pub-b"]  # Replace with your public subnet IDs
  private_subnet_ids  = ["subnet-prd-us-east-1-priv-a", "subnet-prd-us-east-1-priv-b"]  # Replace with your private subnet IDs
  
  # Atlantis configuration
  atlantis_image_tag     = "latest"
  github_user           = "your-github-username"  # Change this
  github_token_secret_name = "atlantis/github-token"  # Store in AWS Secrets Manager
  github_webhook_secret_name = "atlantis/webhook-secret"  # Store in AWS Secrets Manager
  repo_allowlist        = "github.com/your-org/*"  # Change this
  
  # ECS configuration - Production settings
  cpu                   = 1024  # Higher for production
  memory               = 2048   # Higher for production
  desired_count        = 2      # Multiple instances for HA
  
  # SSL certificate (optional - set to null if you don't have one)
  ssl_certificate_arn  = null
  domain_name          = null  # Set if you have a custom domain
  
  # Additional tags
  tags = local.common_tags
}

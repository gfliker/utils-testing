include "root" {
  path = find_in_parent_folders()
}

include "global" {
  path = find_in_parent_folders("global.hcl")
}

include "account" {
  path = find_in_parent_folders("account.hcl")
}

terraform {
  source = "../../../../modules/iam-roles"  # Assuming you have an IAM roles module
}

# Merge variables from includes
locals {
  global_vars  = include.global.locals
  account_vars = include.account.locals
  
  # Account-wide global tags
  global_tags = merge(
    local.global_vars.common_tags,
    local.account_vars.account_tags,
    {
      Scope = "account-global"
      Type  = "cross-region-resources"
    }
  )
}

inputs = {
  # Pass through hierarchical variables
  environment   = local.account_vars.environment
  project_name  = "${local.global_vars.project_name}-${local.account_vars.environment}"
  
  # Account-wide IAM roles and policies
  create_atlantis_assume_roles = true
  
  # Cross-region IAM roles for Atlantis
  atlantis_roles = [
    {
      name        = "atlantis-terraform-role-${local.account_vars.environment}"
      description = "Role for Atlantis to perform Terraform operations in ${local.account_vars.environment}"
      
      # Allow Atlantis to assume this role from any region
      trusted_entities = [
        "arn:aws:iam::${local.account_vars.account_id}:role/*atlantis*"
      ]
      
      # Permissions for Terraform operations
      managed_policies = [
        "arn:aws:iam::aws:policy/PowerUserAccess"
      ]
    }
  ]
  
  # Additional tags
  tags = local.global_tags
}

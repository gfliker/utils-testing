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
  source = "../../../../modules/route53"  # Assuming you have a Route53 module
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
      Type  = "dns-management"
    }
  )
}

inputs = {
  # Pass through hierarchical variables
  environment   = local.account_vars.environment
  project_name  = "${local.global_vars.project_name}-${local.account_vars.environment}"
  
  # Account-wide DNS configuration
  hosted_zones = [
    {
      name        = "${local.account_vars.environment}.${local.global_vars.organization_name}.com"
      description = "Hosted zone for ${local.account_vars.environment} environment"
      
      # Cross-region DNS records can be managed here
      records = [
        {
          name = "atlantis"
          type = "CNAME"
          ttl  = 300
          # Will be updated by regional Atlantis deployments
        }
      ]
    }
  ]
  
  # Additional tags
  tags = local.global_tags
}

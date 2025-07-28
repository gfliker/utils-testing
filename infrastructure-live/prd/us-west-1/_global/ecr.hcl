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

terraform {
  source = "../../../../../modules/ecr"  # Assuming you have an ECR module
}

# Merge variables from includes
locals {
  global_vars  = include.global.locals
  account_vars = include.account.locals
  region_vars  = include.region.locals
  
  # Region-wide global tags
  global_tags = merge(
    local.global_vars.common_tags,
    local.account_vars.account_tags,
    local.region_vars.region_tags,
    {
      Scope = "region-global"
      Type  = "container-registry"
    }
  )
}

inputs = {
  # Pass through hierarchical variables
  aws_region    = local.region_vars.aws_region
  environment   = local.account_vars.environment
  project_name  = "${local.global_vars.project_name}-${local.account_vars.environment}"
  
  # Region-wide ECR repositories
  ecr_repositories = [
    {
      name                 = "${local.global_vars.project_name}-atlantis"
      image_tag_mutability = "MUTABLE"
      scan_on_push        = true
      
      lifecycle_policy = {
        rules = [
          {
            rulePriority = 1
            description  = "Keep last 10 production images"
            selection = {
              tagStatus     = "tagged"
              tagPrefixList = ["v", "prod"]
              countType     = "imageCountMoreThan"
              countNumber   = 10
            }
            action = {
              type = "expire"
            }
          }
        ]
      }
    },
    {
      name                 = "${local.global_vars.project_name}-utilities"
      image_tag_mutability = "MUTABLE"
      scan_on_push        = true
    }
  ]
  
  # Additional tags
  tags = local.global_tags
}

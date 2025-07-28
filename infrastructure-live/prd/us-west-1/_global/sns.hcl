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
  source = "../../../../../modules/sns"  # Assuming you have an SNS module
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
      Type  = "notifications"
    }
  )
}

inputs = {
  # Pass through hierarchical variables
  aws_region    = local.region_vars.aws_region
  environment   = local.account_vars.environment
  project_name  = "${local.global_vars.project_name}-${local.account_vars.environment}"
  
  # Region-wide SNS topics for notifications
  sns_topics = [
    {
      name         = "${local.global_vars.project_name}-alerts-${local.account_vars.environment}-${local.region_vars.aws_region}"
      display_name = "Atlantis Alerts for ${local.account_vars.environment} in ${local.region_vars.aws_region}"
      
      # Email subscriptions for alerts
      subscriptions = [
        {
          protocol = "email"
          endpoint = "devops-team@${local.global_vars.organization_name}.com"
        }
      ]
    },
    {
      name         = "${local.global_vars.project_name}-deployments-${local.account_vars.environment}-${local.region_vars.aws_region}"
      display_name = "Atlantis Deployment Notifications for ${local.account_vars.environment}"
      
      # Slack webhook for deployment notifications
      subscriptions = [
        {
          protocol = "https"
          endpoint = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
        }
      ]
    }
  ]
  
  # Additional tags
  tags = local.global_tags
}

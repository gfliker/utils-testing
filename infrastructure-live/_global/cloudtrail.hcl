include "root" {
  path = find_in_parent_folders()
}

include "global" {
  path = find_in_parent_folders("global.hcl")
}

terraform {
  source = "../../modules/cloudtrail"  # Assuming you have a CloudTrail module
}

# Merge variables from includes
locals {
  global_vars = include.global.locals
  
  # Organization-wide global tags
  global_tags = merge(
    local.global_vars.common_tags,
    {
      Scope = "organization-global"
      Type  = "audit-logging"
    }
  )
}

inputs = {
  # Pass through hierarchical variables
  project_name = local.global_vars.project_name
  
  # Organization-wide CloudTrail configuration
  cloudtrail_name = "${local.global_vars.organization_name}-audit-trail"
  
  # S3 bucket for CloudTrail logs (organization-wide)
  s3_bucket_name = "${local.global_vars.organization_name}-cloudtrail-logs"
  
  # Multi-region trail
  is_multi_region_trail = true
  include_global_service_events = true
  
  # Event selectors for Atlantis-related activities
  event_selectors = [
    {
      read_write_type                 = "All"
      include_management_events       = true
      exclude_management_event_sources = []
      
      data_resources = [
        {
          type   = "AWS::S3::Object"
          values = ["arn:aws:s3:::*terraform-state*/*"]
        }
      ]
    }
  ]
  
  # CloudWatch integration
  cloud_watch_logs_group_arn = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:${local.global_vars.organization_name}-cloudtrail-logs:*"
  
  # Additional tags
  tags = local.global_tags
}

# Data source for current account ID
data "aws_caller_identity" "current" {}

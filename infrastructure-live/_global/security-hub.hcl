include "root" {
  path = find_in_parent_folders()
}

include "global" {
  path = find_in_parent_folders("global.hcl")
}

terraform {
  source = "../../modules/security-hub"  # Assuming you have a Security Hub module
}

# Merge variables from includes
locals {
  global_vars = include.global.locals
  
  # Organization-wide global tags
  global_tags = merge(
    local.global_vars.common_tags,
    {
      Scope = "organization-global"
      Type  = "security-compliance"
    }
  )
}

inputs = {
  # Pass through hierarchical variables
  project_name = local.global_vars.project_name
  
  # Organization-wide Security Hub configuration
  enable_security_hub = true
  enable_default_standards = true
  
  # Enable security standards
  enabled_standards = [
    "arn:aws:securityhub:::ruleset/finding-format/aws-foundational-security-standard/v/1.0.0",
    "arn:aws:securityhub:us-east-1::standard/cis-aws-foundations-benchmark/v/1.2.0"
  ]
  
  # Custom insights for Atlantis infrastructure
  custom_insights = [
    {
      name    = "Atlantis-Infrastructure-Findings"
      filters = {
        resource_tags = [
          {
            key   = "Project"
            value = "atlantis"
          }
        ]
        compliance_status = ["FAILED"]
      }
      group_by_attribute = "ComplianceStatus"
    }
  ]
  
  # SNS topic for Security Hub findings
  sns_topic_arn = "arn:aws:sns:us-east-1:${data.aws_caller_identity.current.account_id}:security-alerts"
  
  # Additional tags
  tags = local.global_tags
}

# Data source for current account ID
data "aws_caller_identity" "current" {}

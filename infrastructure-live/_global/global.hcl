# Global configuration that applies across all accounts
locals {
  # Organization-wide defaults
  organization_name = "my-org"
  project_name      = "atlantis"
  
  # Common tags applied to all resources
  common_tags = {
    Project     = "atlantis"
    Owner       = "devops-team"
    ManagedBy   = "terragrunt"
    Environment = "multi"
  }
  
  # Default naming conventions
  name_prefix = "${local.organization_name}-${local.project_name}"
}

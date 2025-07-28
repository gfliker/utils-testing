# Production account configuration
locals {
  account_name = "prd"
  account_id   = "123456789012"  # Change this to your AWS account ID
  environment  = "prd"
  
  # Production-specific tags
  common_tags = {
    Account     = "production"
    Environment = "prd"
    CostCenter  = "engineering"
  }
}

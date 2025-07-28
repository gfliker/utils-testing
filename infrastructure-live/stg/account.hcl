# Staging account configuration
locals {
  account_name = "stg"
  account_id   = "123456789013"  # Change this to your AWS account ID
  environment  = "stg"
  
  # Staging-specific tags
  common_tags = {
    Account     = "staging"
    Environment = "stg"
    CostCenter  = "engineering"
  }
}ount configuration
locals {
  account_name = "stg"
  account_id   = "123456789013"  # Change this to your staging AWS account ID
  environment  = "stg"
  
  # Staging-specific configuration
  account_tags = {
    Account     = "staging"
    Environment = "stg"
    CostCenter  = "engineering"
  }
}

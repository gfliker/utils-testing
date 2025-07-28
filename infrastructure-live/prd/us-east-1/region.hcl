# US East 1 region configuration
locals {
  aws_region = "us-east-1"
  
  # Region-specific tags
  common_tags = {
    AWSRegion = "us-east-1"
    Timezone = "America/New_York"
  }
  
  # Availability zones for this region
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# US West 1 region configuration
locals {
  aws_region = "us-west-1"
  
  # Region-specific tags
  common_tags = {
    AWSRegion = "us-west-1"
    Timezone = "America/Los_Angeles"
  }
  
  # Availability zones for this region
  availability_zones = ["us-west-1a", "us-west-1c"]
}egion configuration
locals {
  aws_region = "us-west-1"
  
  # Region-specific configuration
  region_tags = {
    Region = "us-west-1"
    Timezone = "America/Los_Angeles"
  }
  
  # Availability zones for this region
  availability_zones = ["us-west-1a", "us-west-1b"]
}

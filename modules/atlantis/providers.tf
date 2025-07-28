# Provider configuration for Atlantis module
# This inherits the default tags from the root provider configuration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Note: The AWS provider configuration is inherited from the root module
# and includes default_tags that will be automatically applied to all resources
# created by this module.

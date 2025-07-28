# Data sources for existing VPC and subnets
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnet" "public" {
  count = length(var.public_subnet_ids)
  id    = var.public_subnet_ids[count.index]
}

data "aws_subnet" "private" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

# Validate that public subnets are actually public
locals {
  public_subnets_validation = [
    for subnet in data.aws_subnet.public :
    subnet.map_public_ip_on_launch
  ]
  
  private_subnets_validation = [
    for subnet in data.aws_subnet.private :
    !subnet.map_public_ip_on_launch
  ]
}

#!/bin/bash

# Script to help identify VPC and subnet IDs for Atlantis deployment
# Usage: ./get-vpc-info.sh [vpc-name-tag]

set -e

VPC_NAME_TAG="${1:-default}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo "Searching for VPC and subnets in region: ${AWS_REGION}"
echo "VPC name tag filter: ${VPC_NAME_TAG}"
echo ""

# Find VPC by Name tag
VPC_ID=$(aws ec2 describe-vpcs \
  --region ${AWS_REGION} \
  --filters "Name=tag:Name,Values=*${VPC_NAME_TAG}*" \
  --query 'Vpcs[0].VpcId' \
  --output text 2>/dev/null || echo "null")

if [ "$VPC_ID" = "null" ] || [ -z "$VPC_ID" ]; then
  echo "❌ No VPC found with name tag containing '${VPC_NAME_TAG}'"
  echo "Available VPCs:"
  aws ec2 describe-vpcs \
    --region ${AWS_REGION} \
    --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
    --output table
  exit 1
fi

echo "✅ Found VPC: ${VPC_ID}"

# Get VPC CIDR
VPC_CIDR=$(aws ec2 describe-vpcs \
  --region ${AWS_REGION} \
  --vpc-ids ${VPC_ID} \
  --query 'Vpcs[0].CidrBlock' \
  --output text)

echo "   CIDR: ${VPC_CIDR}"
echo ""

# Find public subnets (have route to internet gateway)
echo "🔍 Finding public subnets..."
PUBLIC_SUBNETS=$(aws ec2 describe-subnets \
  --region ${AWS_REGION} \
  --filters "Name=vpc-id,Values=${VPC_ID}" "Name=map-public-ip-on-launch,Values=true" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]' \
  --output text)

if [ -z "$PUBLIC_SUBNETS" ]; then
  echo "❌ No public subnets found"
else
  echo "✅ Public subnets:"
  echo "$PUBLIC_SUBNETS" | while read subnet_id az cidr; do
    echo "   ${subnet_id} (${az}) - ${cidr}"
  done
fi

# Find private subnets (don't have public IP assignment)
echo ""
echo "🔍 Finding private subnets..."
PRIVATE_SUBNETS=$(aws ec2 describe-subnets \
  --region ${AWS_REGION} \
  --filters "Name=vpc-id,Values=${VPC_ID}" "Name=map-public-ip-on-launch,Values=false" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]' \
  --output text)

if [ -z "$PRIVATE_SUBNETS" ]; then
  echo "❌ No private subnets found"
else
  echo "✅ Private subnets:"
  echo "$PRIVATE_SUBNETS" | while read subnet_id az cidr; do
    echo "   ${subnet_id} (${az}) - ${cidr}"
  done
fi

echo ""
echo "📋 Terragrunt Configuration:"
echo "vpc_id = \"${VPC_ID}\""

if [ -n "$PUBLIC_SUBNETS" ]; then
  PUBLIC_SUBNET_IDS=$(echo "$PUBLIC_SUBNETS" | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')
  echo "public_subnet_ids = [$(echo $PUBLIC_SUBNET_IDS | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/' | sed 's/", "$/"/')]"
fi

if [ -n "$PRIVATE_SUBNETS" ]; then
  PRIVATE_SUBNET_IDS=$(echo "$PRIVATE_SUBNETS" | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')
  echo "private_subnet_ids = [$(echo $PRIVATE_SUBNET_IDS | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/' | sed 's/", "$/"/')]"
fi

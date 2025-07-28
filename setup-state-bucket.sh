#!/bin/bash

# Script to set up S3 bucket for Terraform state with native locking
# Usage: ./setup-state-bucket.sh <bucket-name> [region]

set -e

BUCKET_NAME="${1}"
AWS_REGION="${2:-us-east-1}"

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: Bucket name is required"
  echo "Usage: $0 <bucket-name> [region]"
  echo "Example: $0 my-terraform-state-bucket us-east-1"
  exit 1
fi

echo "Setting up S3 bucket for Terraform state: ${BUCKET_NAME}"
echo "Region: ${AWS_REGION}"
echo ""

# Check if bucket already exists
if aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
  echo "Bucket ${BUCKET_NAME} already exists"
  read -p "Do you want to configure it for Terraform state? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi
else
  echo "Creating S3 bucket..."
  if [ "$AWS_REGION" = "us-east-1" ]; then
    aws s3 mb "s3://${BUCKET_NAME}"
  else
    aws s3 mb "s3://${BUCKET_NAME}" --region "${AWS_REGION}"
  fi
  echo "Bucket created successfully"
fi

echo ""
echo "Configuring bucket settings..."

# Enable versioning
echo "Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "Enabling server-side encryption..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'

# Block public access
echo "Blocking public access..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Add lifecycle policy to manage old versions
echo "Setting up lifecycle policy for old versions..."
aws s3api put-bucket-lifecycle-configuration \
  --bucket "${BUCKET_NAME}" \
  --lifecycle-configuration '{
    "Rules": [
      {
        "ID": "terraform-state-lifecycle",
        "Status": "Enabled",
        "NoncurrentVersionExpiration": {
          "NoncurrentDays": 90
        },
        "AbortIncompleteMultipartUpload": {
          "DaysAfterInitiation": 7
        }
      }
    ]
  }'

# Set up bucket policy for Terraform access
echo "Setting up bucket policy..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
cat > /tmp/bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${ACCOUNT_ID}:root"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::${BUCKET_NAME}",
        "arn:aws:s3:::${BUCKET_NAME}/*"
      ]
    }
  ]
}
EOF

aws s3api put-bucket-policy \
  --bucket "${BUCKET_NAME}" \
  --policy file:///tmp/bucket-policy.json

rm /tmp/bucket-policy.json

echo ""
echo "S3 bucket setup complete!"
echo ""
echo "Summary:"
echo "   Bucket Name: ${BUCKET_NAME}"
echo "   Region: ${AWS_REGION}"
echo "   Versioning: Enabled"
echo "   Encryption: AES256 with BucketKey"
echo "   Public Access: Blocked"
echo "   Lifecycle: 90-day retention for old versions"
echo ""
echo "Next steps:"
echo "   1. Update your terragrunt.hcl files to use this bucket:"
echo "      bucket = \"${BUCKET_NAME}\""
echo "   2. Deploy your infrastructure:"
echo "      cd infrastructure-live/prd/us-east-1/services/atlantis"
echo "      terragrunt apply"
echo ""
echo "Note: This configuration uses S3 native locking - no DynamoDB table needed!"

#!/bin/bash

# Build and push Atlantis Docker image to ECR
# Usage: ./build-and-push.sh [tag]

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPO_NAME="atlantis-atlantis"  # This should match your project name
IMAGE_TAG="${1:-latest}"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECR repository URL
ECR_REPO_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

echo "Building Docker image..."
docker build -t atlantis:${IMAGE_TAG} .

echo "Tagging image for ECR..."
docker tag atlantis:${IMAGE_TAG} ${ECR_REPO_URL}:${IMAGE_TAG}

echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URL}

echo "Pushing image to ECR..."
docker push ${ECR_REPO_URL}:${IMAGE_TAG}

echo "Successfully pushed ${ECR_REPO_URL}:${IMAGE_TAG}"
echo ""
echo "To update your ECS service with the new image, run:"
echo "aws ecs update-service --cluster atlantis-cluster --service atlantis-service --force-new-deployment --region ${AWS_REGION}"

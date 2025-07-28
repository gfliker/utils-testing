# Atlantis ECS Deployment with Terragrunt

This Terragrunt configuration deploys Atlantis as an ECS Fargate service following the recommended [Terragrunt infrastructure-live](https://docs.gruntwork.io/2.0/docs/overview/concepts/infrastructure-live/) pattern for organizing infrastructure code.

## Project Structure

This project follows the Terragrunt best practice of separating **modules** (reusable infrastructure blueprints) from **live infrastructure** (actual deployed resources). The structure enables:

- **Environment isolation**: Separate configurations for production (`prd`) and staging (`stg`)
- **Multi-region deployments**: Support for `us-east-1` and `us-west-1` regions
- **Hierarchical configuration**: Variables and settings inherit from parent levels
- **DRY principle**: Reusable modules and shared configuration

### Directory Structure

```
my-project/
├── modules/                                    # Reusable Terraform modules
│   └── atlantis/                              # Atlantis ECS service module
│       ├── alb.tf                             # Application Load Balancer
│       ├── data.tf                            # Data sources
│       ├── ecr.tf                             # ECR repository
│       ├── ecs.tf                             # ECS cluster and service
│       ├── iam.tf                             # IAM roles and policies
│       ├── outputs.tf                         # Module outputs
│       ├── security_groups.tf                 # Security groups
│       └── variables.tf                       # Module variables
│
├── infrastructure-live/                        # Live infrastructure deployments
│   ├── _global/                               # 🌐 Organization-wide resources
│   │   ├── global.hcl                         # Global configuration variables
│   │   ├── cloudtrail.hcl                     # Organization audit logging
│   │   └── security-hub.hcl                   # Security compliance monitoring
│   │
│   ├── terragrunt.hcl                         # Root Terragrunt configuration
│   │
│   ├── prd/                                   # 🏢 Production account
│   │   ├── _global/                           # Account-wide resources
│   │   │   ├── iam-roles.hcl                  # Cross-region IAM roles
│   │   │   └── route53.hcl                    # DNS hosted zones
│   │   ├── account.hcl                        # Production account config
│   │   │
│   │   ├── us-east-1/                         # 🌍 US East 1 region
│   │   │   ├── _global/                       # Region-wide resources
│   │   │   │   ├── ecr.hcl                    # Container registries
│   │   │   │   └── sns.hcl                    # Notification topics
│   │   │   ├── region.hcl                     # Region configuration
│   │   │   └── services/                      # 📦 Services category
│   │   │       ├── category.hcl               # Category configuration
│   │   │       └── atlantis/                  # Atlantis service
│   │   │           └── terragrunt.hcl         # Production Atlantis config
│   │   │
│   │   └── us-west-1/                         # 🌍 US West 1 region
│   │       ├── _global/
│   │       │   ├── ecr.hcl
│   │       │   └── sns.hcl
│   │       ├── region.hcl
│   │       └── services/
│   │           ├── category.hcl
│   │           └── atlantis/
│   │               └── terragrunt.hcl
│   │
│   └── stg/                                   # 🧪 Staging account
│       ├── _global/                           # Account-wide resources
│       │   ├── iam-roles.hcl
│       │   └── route53.hcl
│       ├── account.hcl                        # Staging account config
│       │
│       ├── us-east-1/                         # Same structure as production
│       │   ├── _global/
│       │   │   ├── ecr.hcl                    # Staging-optimized ECR lifecycle
│       │   │   └── sns.hcl
│       │   ├── region.hcl
│       │   └── services/
│       │       ├── category.hcl
│       │       └── atlantis/
│       │           └── terragrunt.hcl         # Staging Atlantis config
│       │
│       └── us-west-1/
│           ├── _global/
│           │   ├── ecr.hcl
│           │   └── sns.hcl
│           ├── region.hcl
│           └── services/
│               ├── category.hcl
│               └── atlantis/
│                   └── terragrunt.hcl
│
├── Dockerfile                                  # Atlantis container image
├── build-and-push.sh                          # Script to build and push image
├── get-vpc-info.sh                            # Helper to find VPC information
└── README.md                                  # This documentation
```

### Configuration Hierarchy

The infrastructure follows a hierarchical configuration pattern where each level can define variables and settings that are inherited by child levels:

1. **🌐 Global Level** (`_global/global.hcl`): Organization-wide settings
   - Company name, project naming conventions
   - Common tags applied to all resources
   - Organization-wide resources like CloudTrail, Security Hub

2. **🏢 Account Level** (`account.hcl`): Account-specific configuration
   - Account ID, environment designation (prd/stg)
   - Account-specific tags and settings
   - Cross-region resources like IAM roles, DNS zones

3. **🌍 Region Level** (`region.hcl`): Region-specific configuration
   - AWS region, availability zones
   - Region-specific tags and settings
   - Regional resources like ECR repositories, SNS topics

4. **📦 Category Level** (`category.hcl`): Resource category grouping
   - Category-specific settings (services, networking, data, etc.)
   - Category tags and configuration

5. **🎯 Resource Level** (`terragrunt.hcl`): Individual resource configuration
   - Service-specific settings and variables
   - Combines all inherited configuration from parent levels

### Tagging Strategy

The infrastructure implements a comprehensive tagging strategy using AWS provider default tags that are automatically applied to all resources:

#### Tag Inheritance Hierarchy
Tags are merged from multiple levels, with more specific levels overriding general ones:

```hcl
# Global tags (applied to all resources)
Project     = "atlantis"
Owner       = "devops-team"
ManagedBy   = "terragrunt"

# Account-level tags
Account     = "production" | "staging"
Environment = "prd" | "stg"
CostCenter  = "engineering"

# Region-level tags
AWSRegion   = "us-east-1" | "us-west-1"
Timezone    = "America/New_York" | "America/Los_Angeles"

# Provider-added tags
Region      = var.aws_region
ManagedBy   = "terraform"
```

#### Benefits
- **Automatic Application**: All AWS resources get tagged without manual intervention
- **Cost Tracking**: Easy cost allocation by environment, region, and project
- **Compliance**: Consistent tagging across all infrastructure
- **Resource Management**: Easy filtering and grouping in AWS Console

### Environment Differences

| Aspect | Production (`prd`) | Staging (`stg`) |
|--------|-------------------|-----------------|
| **Resources** | Higher CPU/memory (1024/2048) | Lower CPU/memory (512/1024) |
| **Instances** | 2 for high availability | 1 for cost optimization |
| **ECR Lifecycle** | Keep 10 production images | Keep 5 staging images, aggressive cleanup |
| **Secrets** | `atlantis/github-token` | `atlantis/github-token-stg` |
| **DNS** | `prd.my-org.com` | `stg.my-org.com` |
| **Monitoring** | Full monitoring suite | Basic monitoring |

## Architecture

- **ECR Repository**: Stores the Atlantis Docker image
- **Application Load Balancer**: Exposes Atlantis to the internet for GitHub webhooks
- **ECS Fargate Service**: Runs the Atlantis container
- **Security Groups**: Controls network access
- **IAM Roles**: Provides necessary permissions for ECS and Atlantis operations
- **CloudWatch Logs**: Captures application logs
- **S3 State Management**: Uses S3 native locking for Terraform state (no DynamoDB required)

### State Management

This configuration uses **S3 native locking** for Terraform state management, which provides:

✅ **Simplified Infrastructure**: No need for separate DynamoDB table
✅ **Reduced Costs**: Eliminates DynamoDB charges for state locking
✅ **Built-in Reliability**: Leverages S3's native consistency and durability
✅ **Automatic Cleanup**: No orphaned lock records to manage
✅ **Version Control**: S3 versioning provides state history and rollback capability

## Prerequisites

1. **Existing VPC and Subnets**: This configuration assumes you have an existing VPC with:
   - At least 2 public subnets (for the ALB)
   - At least 2 private subnets (for the ECS tasks)
   - Proper routing setup (internet gateway for public subnets, NAT gateway for private subnets)

2. **AWS Secrets Manager**: Create the following secrets:
   ```bash
   # GitHub Personal Access Token
   aws secretsmanager create-secret \
     --name "atlantis/github-token" \
     --description "GitHub token for Atlantis" \
     --secret-string "your-github-token"

   # GitHub Webhook Secret
   aws secretsmanager create-secret \
     --name "atlantis/webhook-secret" \
     --description "GitHub webhook secret for Atlantis" \
     --secret-string "your-webhook-secret"
   ```

3. **S3 Bucket**: For Terraform state management with native locking:
   
   **Option A: Use the setup script (Recommended):**
   ```bash
   # Use the provided script to set up the bucket with optimal configuration
   ./setup-state-bucket.sh my-terraform-state-bucket us-east-1
   ```
   
   **Option B: Manual setup:**
   ```bash
   # Create S3 bucket for state with versioning enabled
   aws s3 mb s3://my-terraform-state-bucket
   
   # Enable versioning for better state management
   aws s3api put-bucket-versioning \
     --bucket my-terraform-state-bucket \
     --versioning-configuration Status=Enabled
   
   # Enable server-side encryption
   aws s3api put-bucket-encryption \
     --bucket my-terraform-state-bucket \
     --server-side-encryption-configuration '{
       "Rules": [
         {
           "ApplyServerSideEncryptionByDefault": {
             "SSEAlgorithm": "AES256"
           }
         }
       ]
     }'
   ```

## Configuration

1. **Update Infrastructure Variables**: Navigate to the specific environment and region you want to deploy:
   
   **For Production US-East-1:**
   ```bash
   cd infrastructure-live/prd/us-east-1/services/atlantis
   # Edit terragrunt.hcl with your specific values
   ```
   
   **For Staging US-West-1:**
   ```bash
   cd infrastructure-live/stg/us-west-1/services/atlantis
   # Edit terragrunt.hcl with your specific values
   ```

2. **Required Updates in terragrunt.hcl**:
   - `vpc_id`: Your existing VPC ID for that region
   - `public_subnet_ids`: List of public subnet IDs
   - `private_subnet_ids`: List of private subnet IDs
   - `github_user`: Your GitHub username
   - `repo_allowlist`: GitHub repositories that Atlantis can access

3. **Global Configuration**: Update organization-wide settings in:
   ```bash
   # Edit global settings
   infrastructure-live/_global/global.hcl
   
   # Update account-specific settings
   infrastructure-live/prd/account.hcl
   infrastructure-live/stg/account.hcl
   ```

4. **Optional SSL Configuration**:
   - Set `ssl_certificate_arn` if you have an SSL certificate in ACM
   - Set `domain_name` if you have a custom domain

## Deployment Patterns

The hierarchical structure supports various deployment patterns:

### Single Environment Deployment
Deploy Atlantis to a specific environment and region:
```bash
# Deploy to production us-east-1
cd infrastructure-live/prd/us-east-1/services/atlantis
terragrunt apply

# Deploy to staging us-west-1
cd infrastructure-live/stg/us-west-1/services/atlantis
terragrunt apply
```

### Multi-Region Deployment
Deploy to all regions in an account:
```bash
# Deploy to all production regions
cd infrastructure-live/prd
terragrunt run-all apply --terragrunt-include-dir="*/services/atlantis"

# Deploy to all staging regions
cd infrastructure-live/stg
terragrunt run-all apply --terragrunt-include-dir="*/services/atlantis"
```

### Global Resources Deployment
Deploy shared resources at different hierarchy levels:
```bash
# Deploy organization-wide resources (CloudTrail, Security Hub)
cd infrastructure-live/_global
terragrunt run-all apply

# Deploy account-wide resources (IAM roles, DNS)
cd infrastructure-live/prd/_global
terragrunt run-all apply

# Deploy region-wide resources (ECR, SNS)
cd infrastructure-live/prd/us-east-1/_global
terragrunt run-all apply
```

### Full Environment Setup
Deploy everything for a complete environment:
```bash
# Deploy all production infrastructure
cd infrastructure-live
terragrunt run-all apply --terragrunt-include-dir="prd/**"

# Deploy all staging infrastructure
cd infrastructure-live
terragrunt run-all apply --terragrunt-include-dir="stg/**"
```

## Deployment

### Step 1: Deploy Global Resources
Deploy infrastructure resources in the following order:

#### Organization-Wide Resources (Deploy Once)
```bash
# Deploy CloudTrail for audit logging
cd infrastructure-live/_global/cloudtrail
terragrunt apply
```

#### Regional Resources (Deploy per Region)
```bash
# Deploy ECR repository for container images
cd infrastructure-live/prd/us-east-1/_global/ecr
terragrunt apply

# Deploy SNS topic for alerts and notifications
cd infrastructure-live/prd/us-east-1/_global/sns
terragrunt apply

# Repeat for other regions if needed
cd infrastructure-live/prd/us-west-1/_global/ecr
terragrunt apply
```

#### Deploy All Global Resources at Once (Alternative)
```bash
# Deploy all global resources for production
cd infrastructure-live
terragrunt run-all apply --terragrunt-include-dir="_global/**"
terragrunt run-all apply --terragrunt-include-dir="prd/*/_global/**"

# Deploy all global resources for staging
terragrunt run-all apply --terragrunt-include-dir="stg/*/_global/**"
```

### Step 2: Build and Push Docker Image
```bash
# Build and push the Atlantis image to ECR
./build-and-push.sh latest

# Or specify a specific tag
./build-and-push.sh v1.0.0
```

### Step 3: Deploy Atlantis Service
Choose your target environment and region:

**Production Deployment:**
```bash
# Deploy to production us-east-1
cd infrastructure-live/prd/us-east-1/services/atlantis
terragrunt apply

# Deploy to production us-west-1
cd infrastructure-live/prd/us-west-1/services/atlantis
terragrunt apply
```

**Staging Deployment:**
```bash
# Deploy to staging us-east-1
cd infrastructure-live/stg/us-east-1/services/atlantis
terragrunt apply

# Or deploy to all staging regions at once
cd infrastructure-live/stg
terragrunt run-all apply --terragrunt-include-dir="*/services/atlantis"
```

### Step 4: Configure GitHub Webhooks
   - Go to your GitHub repository settings
   - Add a webhook with:
     - URL: The ALB DNS name or custom domain (from outputs)
     - Content type: `application/json`
     - Secret: The webhook secret you stored in Secrets Manager
     - Events: Select "Pull requests" and "Pushes"

## Accessing Atlantis

After deployment, Atlantis will be available at:
- HTTP: `http://<alb-dns-name>`
- HTTPS: `https://<custom-domain>` (if SSL certificate is configured)

The health check endpoint is available at `/healthz`.

## Security Considerations

1. **Network Security**: ECS tasks run in private subnets and only accept traffic from the ALB
2. **IAM Permissions**: The ECS task role has permissions to assume roles for Terraform operations
3. **Secrets Management**: Sensitive data is stored in AWS Secrets Manager
4. **Container Security**: ECR repository has vulnerability scanning enabled

## Scaling

- Modify `desired_count` to run multiple Atlantis instances
- Adjust `cpu` and `memory` based on your workload requirements
- The ALB will distribute traffic across multiple instances

## Managing Infrastructure

### Viewing Deployed Resources
```bash
# See what's deployed in production
cd infrastructure-live/prd
terragrunt run-all plan

# Check specific service status
cd infrastructure-live/prd/us-east-1/services/atlantis
terragrunt show
```

### Updating Configuration
When making changes, you can target specific levels:

```bash
# Update global configuration for all environments
cd infrastructure-live/_global
terragrunt apply

# Update only production account resources
cd infrastructure-live/prd/_global
terragrunt run-all apply

# Update specific service
cd infrastructure-live/prd/us-east-1/services/atlantis
terragrunt apply
```

### Environment Promotion
Promote changes from staging to production:

```bash
# Test in staging first
cd infrastructure-live/stg/us-east-1/services/atlantis
terragrunt apply

# If successful, promote to production
cd infrastructure-live/prd/us-east-1/services/atlantis
terragrunt apply
```

### Helper Scripts

Use the included helper scripts for common tasks:

```bash
# Find your VPC and subnet information
./get-vpc-info.sh my-vpc-name

# Build and push new image version
./build-and-push.sh v2.0.0

# Update ECS service with new image
aws ecs update-service \
  --cluster atlantis-prd-us-east-1 \
  --service atlantis-service \
  --force-new-deployment
```

## Monitoring

- Application logs are sent to CloudWatch Logs under `/ecs/atlantis`
- ECS service metrics are available in CloudWatch
- ALB access logs can be enabled if needed

## Cleanup

To destroy infrastructure, follow the reverse order of deployment:

### Destroy Specific Service
```bash
# Destroy staging atlantis service
cd infrastructure-live/stg/us-east-1/services/atlantis
terragrunt destroy

# Destroy production atlantis service
cd infrastructure-live/prd/us-east-1/services/atlantis
terragrunt destroy
```

### Destroy Entire Environment
```bash
# Destroy all staging infrastructure
cd infrastructure-live/stg
terragrunt run-all destroy

# Destroy all production infrastructure (be careful!)
cd infrastructure-live/prd
terragrunt run-all destroy
```

### Destroy Global Resources
```bash
# Destroy account-wide resources
cd infrastructure-live/prd/_global
terragrunt run-all destroy

# Destroy organization-wide resources (last step)
cd infrastructure-live/_global
terragrunt run-all destroy
```

**⚠️ Important Notes:**
- ECR images must be deleted manually before destroying repositories
- S3 state bucket with versioning may require manual cleanup of old versions
- CloudTrail logs should be preserved for compliance
- Always test destroy operations in staging first
- S3 bucket versioning helps with state recovery but may accumulate costs over time

## Troubleshooting

### Common Issues

1. **VPC/Subnet Not Found**: Use `./get-vpc-info.sh` to verify your VPC and subnet IDs
2. **ECR Push Failures**: Ensure you have proper AWS credentials and ECR permissions
3. **State Lock Issues**: Check S3 bucket permissions and connectivity
4. **DNS Resolution**: Verify Route53 hosted zones and NS record propagation
5. **S3 State Bucket Access**: Ensure proper IAM permissions for S3 bucket operations

### Useful Commands

```bash
# Check Terragrunt configuration
terragrunt validate

# Debug Terragrunt variables
terragrunt run-all output

# Force unlock stuck state
terragrunt force-unlock <lock-id>

# Refresh state without making changes
terragrunt refresh
```

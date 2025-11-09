**!!! WORK IN PROGRESS / MAY CONTAIN ERRORS !!!**


# Backend Infrastructure

Terraform configuration for AWS: S3, CloudFront, Lambda, DynamoDB, API Gateway, Route 53, ACM.

## Prerequisites

- AWS account with Route 53 hosted zone for your domain
- Terraform 1.0+ and AWS CLI v2
- AWS SSO/IAM configured with AdministratorAccess

## Quick Start

```bash
# 1. Bootstrap Terraform state bucket (first time only)
cd terraform/bootstrap-tfstate
# Edit create-tf-state.sh with your bucket name
./create-tf-state.sh

# 2. Update backend configuration
# Edit terraform/backend.tf with your bucket name

# 3. Set your domain
# Edit terraform/variables.tf: root_domain = "yourdomain.com"

# 4. Deploy
cd terraform
aws sso login
terraform init
terraform plan
terraform apply
```

## Key Outputs

After deployment, note these values for frontend integration:
- `api_gateway_url` - API endpoint for visitor counter
- `cloudfront_distribution_id` - For cache invalidation
- `s3_bucket_name` - For uploading static content
- `website_url` - Live site URL

## Common Commands

```bash
terraform plan          # Preview changes
terraform apply         # Deploy changes
terraform destroy       # Remove all resources
terraform output        # Show output values
```

## Architecture

```
User → CloudFront → S3 (static blog)
User → API Gateway → Lambda → DynamoDB (visitor counter)
```

## State Management

- State stored in S3 with native locking (no DynamoDB needed)
- Configure in `backend.tf` before first `terraform init`

## Cost Estimate

~$1-2/month: Route 53 ($0.50) + minimal S3/Lambda/DynamoDB/CloudFront

Set up AWS Budget alerts at $1, $5, $10 to avoid surprises.

## Troubleshooting

- **No credentials**: Run `aws sso login`
- **Backend changed**: Run `terraform init -reconfigure`
- **ACM pending**: Wait 5-10 min for DNS propagation
- **CloudFront 403**: Check `cloudfront-function.tf` is applied

## Known Issues

- CloudFront deletion takes 15-20 min (must disable first)
- Test `destroy` → `apply` cycle in sandbox before production use

# GitHub Actions OIDC Setup for Backend Deployment

This document explains how to set up GitHub Actions with AWS OIDC authentication for secure, credential-free CI/CD.

## Overview

The workflow at [.github/workflows/terraform-deploy.yaml](../.github/workflows/terraform-deploy.yaml) automatically:
1. Runs Terraform to deploy infrastructure
2. Executes pytest tests against the live API endpoint

**Security**: Uses OIDC instead of long-lived AWS credentials (no `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY`).

## Prerequisites

- AWS account with admin access (for initial IAM setup)
- GitHub repository with backend code
- Terraform state bucket already created: `crc-terraform-state-sk`

## Step 1: Create OIDC Identity Provider in AWS

1. Go to **IAM Console** → **Identity Providers** → **Add Provider**
2. Select **OpenID Connect**
3. Configure:
   - **Provider URL**: `https://token.actions.githubusercontent.com`
   - **Audience**: `sts.amazonaws.com`
4. Click **Add Provider**

**AWS CLI alternative**:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## Step 2: Create IAM Role for GitHub Actions

### Trust Policy

Create `trust-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

**Replace**:
- `YOUR_ACCOUNT_ID`: Your AWS account ID (12 digits)
- `YOUR_GITHUB_USERNAME`: Your GitHub username
- `YOUR_REPO_NAME`: Repository name (e.g., `crc-restart`)

**Example**: For repo `github.com/johndoe/crc-restart`, use `repo:johndoe/crc-restart:*`

### Create the Role

```bash
# Replace YOUR_ACCOUNT_ID, YOUR_GITHUB_USERNAME, YOUR_REPO_NAME in trust-policy.json first

aws iam create-role \
  --role-name GitHubActions-Terraform-Backend \
  --assume-role-policy-document file://trust-policy.json \
  --description "GitHub Actions role for backend Terraform deployment"
```

## Step 3: Attach Permissions Policy

Use the least-privilege policy from [iam-policy.json](./iam-policy.json):

```bash
aws iam put-role-policy \
  --role-name GitHubActions-Terraform-Backend \
  --policy-name TerraformBackendPermissions \
  --policy-document file://iam-policy.json
```

**What this policy allows** (least privilege):
- **S3**: Manage Terraform state bucket + blog hosting bucket
- **CloudFront**: Create/update/delete distribution and functions
- **ACM**: Request and manage SSL certificates
- **Route 53**: Manage DNS records
- **DynamoDB**: Create/manage visitor counter table
- **Lambda**: Deploy and update visitor counter function
- **API Gateway**: Create REST API for Lambda
- **IAM**: Create Lambda execution roles only
- **CloudWatch Logs**: Manage Lambda log groups

## Step 4: Configure GitHub Secrets

Go to **GitHub repository** → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `AWS_ROLE_ARN` | ARN of the IAM role created in Step 2 | `arn:aws:iam::123456789012:role/GitHubActions-Terraform-Backend` |
| `AWS_REGION` | AWS region for resources | `eu-central-1` |

**Find your role ARN**:
```bash
aws iam get-role --role-name GitHubActions-Terraform-Backend --query 'Role.Arn' --output text
```

## Step 5: Test the Workflow

### Option 1: Manual Trigger
1. Go to **GitHub Actions** tab
2. Select **Deploy Backend Infrastructure** workflow
3. Click **Run workflow** → **Run workflow**
4. Monitor logs to verify OIDC authentication works

### Option 2: Push Trigger
```bash
cd /home/se/Code/crc-restart/backend
git add .github/workflows/terraform-deploy.yaml
git commit -m "Add Terraform deployment workflow"
git push origin main
```

### Verify Success

Check the workflow run for:
1. ✅ **Configure AWS Credentials** step succeeds
2. ✅ **Verify AWS Identity** shows correct role ARN
3. ✅ **Terraform Apply** completes without errors
4. ✅ **Run pytest** tests pass

## Workflow Breakdown

### Job 1: `terraform`
```yaml
steps:
  - Configure AWS Credentials (OIDC)
  - Verify AWS Identity
  - Setup Terraform
  - Terraform Format Check
  - Terraform Init (with S3 backend)
  - Terraform Validate
  - Terraform Plan
  - Terraform Apply (auto-approve on main branch)
  - Capture outputs (API endpoint)
```

### Job 2: `test`
```yaml
steps:
  - Checkout code
  - Setup Python 3.11
  - Install pytest and requests
  - Run pytest-request.py against live API
  - Test summary
```

**Dependency**: `test` waits for `terraform` to complete successfully.

## Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Cause**: Trust policy doesn't allow your repository.

**Fix**: Check `token.actions.githubusercontent.com:sub` condition in trust policy matches your repo:
```bash
aws iam get-role --role-name GitHubActions-Terraform-Backend --query 'Role.AssumeRolePolicyDocument'
```

Should contain: `"repo:YOUR_USERNAME/YOUR_REPO:*"`

### Error: "AccessDenied" during Terraform apply

**Cause**: IAM policy missing required permissions.

**Fix**: Check CloudWatch Logs for specific action denied, add to policy:
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --max-results 5
```

### Error: "Error loading state: AccessDenied (S3)"

**Cause**: Role can't access Terraform state bucket.

**Fix**: Verify bucket name in policy matches `backend.tf`:
```json
"Resource": [
  "arn:aws:s3:::crc-terraform-state-sk",
  "arn:aws:s3:::crc-terraform-state-sk/*"
]
```

### Pytest fails with connection errors

**Cause**: API Gateway endpoint not yet available or incorrect URL in test.

**Fix**: Check Terraform outputs and update `pytest-request.py` with correct URL:
```bash
cd backend/terraform
terraform output api_endpoint
```

## Security Best Practices

✅ **OIDC instead of credentials**: No long-lived secrets in GitHub
✅ **Least privilege IAM policy**: Only permissions needed for Terraform resources
✅ **Repository-specific trust policy**: Only your repo can assume the role
✅ **Encrypted Terraform state**: `encrypt = true` in `backend.tf`
✅ **Branch protection**: Consider requiring approvals for `main` branch

## Cost Considerations

GitHub Actions usage:
- **Public repos**: Unlimited minutes (free)
- **Private repos**: 2,000 minutes/month (free tier), then $0.008/minute

Workflow runtime: ~3-5 minutes per deployment

## What's Next

After confirming this works:
1. Add manual approval step for production deployments
2. Set up Terraform plan preview as PR comments
3. Add destroy protection for critical resources
4. Consider separate staging/production workflows
5. Add SBOM generation and security scanning

## References

- [GitHub OIDC in AWS Official Docs](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC Provider Docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Terraform S3 Backend Docs](https://developer.hashicorp.com/terraform/language/backend/s3)
- [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)

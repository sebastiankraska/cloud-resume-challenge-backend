# Quick Setup Guide - GitHub Actions OIDC

**Goal**: Deploy backend infrastructure automatically via GitHub Actions with secure OIDC authentication.

## 5-Minute Setup

### 1. Create OIDC Provider
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 2. Create IAM Role

**Create trust-policy.json** (replace placeholders):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"},
      "StringLike": {"token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/YOUR_REPO:*"}
    }
  }]
}
```

**Create role**:
```bash
aws iam create-role \
  --role-name GitHubActions-Terraform-Backend \
  --assume-role-policy-document file://trust-policy.json
```

### 3. Attach Permissions
```bash
aws iam put-role-policy \
  --role-name GitHubActions-Terraform-Backend \
  --policy-name TerraformBackendPermissions \
  --policy-document file://iam-policy.json
```

### 4. Get Role ARN
```bash
aws iam get-role \
  --role-name GitHubActions-Terraform-Backend \
  --query 'Role.Arn' \
  --output text
```

### 5. Add GitHub Secrets

Go to **GitHub repo** → **Settings** → **Secrets** → **Actions**:

- `AWS_ROLE_ARN`: (output from step 4)
- `AWS_REGION`: `eu-central-1`

### 6. Push and Test
```bash
git add .github/workflows/terraform-deploy.yaml
git commit -m "Add CI/CD workflow"
git push origin main
```

Watch **Actions** tab for deployment progress.

## What the Workflow Does

1. ✅ Authenticates to AWS via OIDC (no credentials!)
2. ✅ Runs `terraform init` with S3 backend
3. ✅ Validates and plans infrastructure changes
4. ✅ Applies changes (auto-approve on main branch)
5. ✅ Runs pytest tests against live API endpoint

## Verify It Works

Check for these in GitHub Actions logs:

```
✓ Configure AWS Credentials
✓ Verify AWS Identity
  AssumedRoleArn: arn:aws:iam::123456789012:role/GitHubActions-Terraform-Backend
✓ Terraform Apply
  Apply complete! Resources: 15 added, 0 changed, 0 destroyed.
✓ Run pytest
  test_endpoint_returns_200 PASSED
  test_counter_increases_on_another_try PASSED
```

## Common Issues

| Error | Fix |
|-------|-----|
| "Not authorized to perform sts:AssumeRoleWithWebIdentity" | Check trust policy `sub` matches `repo:USERNAME/REPO:*` |
| "AccessDenied" on S3 state bucket | Verify bucket name in `iam-policy.json` matches `backend.tf` |
| Pytest fails with 404 | Check `pytest-request.py` has correct API endpoint URL |

## Security Notes

✅ No AWS credentials stored in GitHub (OIDC uses temporary tokens)
✅ IAM role only accessible from your specific repository
✅ Least-privilege permissions (only what Terraform needs)
✅ Terraform state encrypted in S3

## Next Steps

After confirming it works:
- [ ] Add manual approval for production deploys
- [ ] Set up Terraform plan preview on PRs
- [ ] Add branch protection rules
- [ ] Consider separate staging/production workflows

Full details: [GITHUB_ACTIONS_SETUP.md](./GITHUB_ACTIONS_SETUP.md)

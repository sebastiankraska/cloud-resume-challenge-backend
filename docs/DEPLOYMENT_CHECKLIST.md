# GitHub Actions Deployment Checklist

Use this checklist during Hour 3 of your sprint (GitHub Actions + OIDC + IAM setup).

## Pre-Flight Checks

- [ ] Terraform state bucket exists: `crc-terraform-state-sk`
- [ ] All Terraform resources defined (DynamoDB, Lambda, API Gateway)
- [ ] Lambda function code written and tested locally
- [ ] Pytest test file ready at `terraform/tests/pytest-request.py`
- [ ] AWS CLI configured with admin access (for initial setup)

## OIDC Setup (15 minutes)

### AWS Console Steps

- [ ] Create OIDC Identity Provider in IAM
  - URL: `https://token.actions.githubusercontent.com`
  - Audience: `sts.amazonaws.com`
  - Verify provider appears in IAM → Identity Providers

- [ ] Create IAM Role `GitHubActions-Terraform-Backend`
  - Copy your AWS account ID: `aws sts get-caller-identity --query Account --output text`
  - Update `trust-policy.json` with:
    - Your AWS account ID
    - Your GitHub username
    - Your repository name
  - Create role via CLI or console
  - Verify trust policy is correct

- [ ] Attach permissions policy
  - Use `iam-policy.json` from docs/
  - Attach as inline policy named `TerraformBackendPermissions`
  - Verify all permissions sections are included

- [ ] Copy Role ARN for GitHub Secrets
  - Run: `aws iam get-role --role-name GitHubActions-Terraform-Backend --query 'Role.Arn' --output text`
  - Save ARN to clipboard

## GitHub Configuration (5 minutes)

- [ ] Add GitHub Secrets
  - Go to repo → Settings → Secrets and variables → Actions
  - Add `AWS_ROLE_ARN`: (paste ARN from previous step)
  - Add `AWS_REGION`: `eu-central-1`
  - Verify both secrets show green checkmarks

- [ ] Review workflow file
  - Open `.github/workflows/terraform-deploy.yaml`
  - Verify `role-to-assume: ${{ secrets.AWS_ROLE_ARN }}`
  - Verify `aws-region: ${{ secrets.AWS_REGION }}`
  - Verify `working-directory: terraform` is correct

## First Deployment (20 minutes)

### Test Workflow Manually

- [ ] Go to Actions tab → Deploy Backend Infrastructure
- [ ] Click "Run workflow" → Run workflow
- [ ] Watch logs in real-time

### Verify Each Step

- [ ] ✅ Checkout code succeeds
- [ ] ✅ Configure AWS Credentials succeeds
  - Check for: "Assuming role with OIDC"
- [ ] ✅ Verify AWS Identity succeeds
  - Look for: `AssumedRoleArn: arn:aws:iam::...`
- [ ] ✅ Terraform Init succeeds
  - Look for: "Terraform has been successfully initialized!"
- [ ] ✅ Terraform Validate succeeds
  - Look for: "Success! The configuration is valid."
- [ ] ✅ Terraform Plan succeeds
  - Review planned changes (resources to create)
- [ ] ✅ Terraform Apply succeeds
  - Look for: "Apply complete! Resources: X added, 0 changed, 0 destroyed."
- [ ] ✅ Python setup succeeds
- [ ] ✅ Pytest runs successfully
  - All tests should pass

### Verify Infrastructure Created

- [ ] Check DynamoDB table exists
  ```bash
  aws dynamodb list-tables --region eu-central-1
  ```

- [ ] Check Lambda function exists
  ```bash
  aws lambda list-functions --region eu-central-1
  ```

- [ ] Check API Gateway exists
  ```bash
  aws apigatewayv2 get-apis --region eu-central-1
  ```

- [ ] Test API endpoint manually
  ```bash
  curl https://YOUR_API_ENDPOINT/visitor-count
  ```

## Push-Based Deployment Test (5 minutes)

- [ ] Make small change to Terraform (e.g., add comment)
  ```bash
  cd /home/se/Code/crc-restart/backend/terraform
  # Edit any .tf file, add comment
  git add .
  git commit -m "Test CI/CD workflow"
  git push origin main
  ```

- [ ] Verify workflow triggers automatically
  - Check Actions tab shows new run
  - Verify it completes successfully

## Troubleshooting Decision Tree

### OIDC Authentication Fails

**Error**: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

1. [ ] Check trust policy `sub` condition
   ```bash
   aws iam get-role --role-name GitHubActions-Terraform-Backend \
     --query 'Role.AssumeRolePolicyDocument.Statement[0].Condition'
   ```
   Should show: `"repo:USERNAME/REPO:*"`

2. [ ] Verify OIDC provider exists
   ```bash
   aws iam list-open-id-connect-providers
   ```

3. [ ] Check GitHub secrets are set correctly
   - AWS_ROLE_ARN should start with `arn:aws:iam::`
   - AWS_REGION should be `eu-central-1`

### Terraform State Access Denied

**Error**: "Error loading state: AccessDenied"

1. [ ] Verify S3 bucket name in IAM policy matches `backend.tf`
   - Policy: `arn:aws:s3:::crc-terraform-state-sk`
   - backend.tf: `bucket = "crc-terraform-state-sk"`

2. [ ] Check IAM role has S3 permissions
   ```bash
   aws iam get-role-policy \
     --role-name GitHubActions-Terraform-Backend \
     --policy-name TerraformBackendPermissions
   ```

### Terraform Apply Fails with AccessDenied

**Error**: "Error creating [RESOURCE]: AccessDenied"

1. [ ] Identify which AWS service failed (DynamoDB, Lambda, etc.)
2. [ ] Check IAM policy includes required actions for that service
3. [ ] Add missing permissions to `iam-policy.json`
4. [ ] Update role policy:
   ```bash
   aws iam put-role-policy \
     --role-name GitHubActions-Terraform-Backend \
     --policy-name TerraformBackendPermissions \
     --policy-document file://iam-policy.json
   ```

### Pytest Fails

**Error**: Tests fail with connection errors or 404

1. [ ] Verify API endpoint is correct in `pytest-request.py`
   ```bash
   cd backend/terraform
   terraform output api_endpoint
   ```

2. [ ] Update test file URL if needed
3. [ ] Check API Gateway was created successfully
   ```bash
   aws apigatewayv2 get-apis --region eu-central-1 --query 'Items[].ApiEndpoint'
   ```

4. [ ] Test endpoint manually:
   ```bash
   curl $(terraform output -raw api_endpoint)
   ```

## Post-Deployment Validation

- [ ] All GitHub Actions steps green ✅
- [ ] DynamoDB table visible in AWS console
- [ ] Lambda function visible and contains code
- [ ] API Gateway endpoint responds to requests
- [ ] Pytest tests all pass
- [ ] Counter increments on multiple requests
- [ ] No errors in CloudWatch Logs

## Security Review

- [ ] No AWS credentials stored in GitHub Secrets (only role ARN)
- [ ] IAM trust policy is repository-specific
- [ ] IAM permissions follow least privilege
- [ ] Terraform state is encrypted (`encrypt = true`)
- [ ] S3 state bucket has versioning enabled (optional but recommended)

## Interview Preparation Notes

**What to highlight**:
- "I used OIDC instead of long-lived credentials for security"
- "The IAM policy follows least privilege - only permissions Terraform needs"
- "The trust policy ensures only my specific repository can assume the role"
- "Automated testing runs against the live API after deployment"

**What to explain if asked**:
- Why OIDC over credentials (temporary tokens, no rotation needed)
- How the workflow ensures infrastructure changes are tested
- Why separate jobs for terraform and testing (clean separation of concerns)
- What would change for production (manual approval, separate environments)

## Time Budget

| Task | Estimated Time |
|------|----------------|
| OIDC Provider setup | 5 min |
| IAM Role creation | 10 min |
| GitHub Secrets config | 5 min |
| First workflow run | 15 min |
| Troubleshooting (if needed) | 15 min |
| Push-based test | 5 min |
| Validation | 5 min |
| **Total** | **60 min** |

## Success Criteria

✅ Workflow completes successfully on push to main
✅ All Terraform resources created
✅ Pytest tests pass
✅ No long-lived AWS credentials in GitHub
✅ Can explain OIDC setup confidently in interview

## Next: Hour 4 - Burn Down Test

After confirming CI/CD works, proceed to destroying and rebuilding all infrastructure to prove reproducibility.

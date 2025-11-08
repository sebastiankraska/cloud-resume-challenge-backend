#!/bin/bash
# Terraform can lock the Statefile with S3 and does not require a dynamoDB table anymore as of November 2025, that is why I do not create a DynamoDB for locking, see https://developer.hashicorp.com/terraform/language/backend/s3

# For further protection, consider enabling "Multi-factor authentication (MFA) delete". I have no time for this right now becauses it seems to require the root account instead of IAM

# break on any error
set -euo pipefail

# variables
BUCKET="crc-terraform-state-sk"
REGION="eu-central-1"

# validate AWS connection
aws sts get-caller-identity

# create bucket
if [ "$REGION" = "us-east-1" ]; then # a quirk of the s3 API when it is run on us-east-1
    aws s3api create-bucket \
        --bucket "$BUCKET" \
        --region "$REGION"
else
    aws s3api create-bucket \
        --bucket "$BUCKET" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
fi

# enable bucket protection (should be default, but it is safer)
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# block public access to bucket (should be default, but it is safer)
aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# enable bucket versioning 
aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled

# success
echo "Totally done"

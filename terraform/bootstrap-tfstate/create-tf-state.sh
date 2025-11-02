#!/bin/bash
# break on any error
set -euo pipefail

# variables
BUCKET="crc-terraform-state-sk"
REGION="eu-central-1"
TABLE="crc-terraform-lock"

# validate AWS connection
aws sts get-caller-identity

aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION" \
    > /dev/null # redirect output, otherwise the script is 'stuck' on the JSON output of dynamoDB creation

# create bucket
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
        --bucket "$BUCKET" \
        --region "$REGION"
else
    aws s3api create-bucket \
        --bucket "$BUCKET" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
fi

# enable protection (this should be default with newer AWS accounts, but Claude Code recommends it, so ...)
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# block public access (should be default too, but you never know)
aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# enable versioning 
aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled

# while true; do
#   status=$(aws dynamodb describe-table --table-name $TABLE --query 'Table.TableStatus' --output text 2>/dev/null)
  
#   if [ "$status" = "ACTIVE" ]; then
#     echo "Table is ready!"
#     break
#   elif [ "$status" = "CREATING" ]; then
#     echo "Table still creating... waiting"
#     sleep 5
#   else
#     echo "Table status: $status"
#     sleep 5
#   fi
# done

echo "Waiting for dynamoDB table to be created ... this may take up to 30 seconds ..."
aws dynamodb wait table-exists --table-name "$TABLE"
echo "Table is ready!"

# Turn on deletion protection
aws dynamodb update-table --table-name $TABLE --deletion-protection-enabled > /dev/null

# Enable bucket versioning
echo "all done"

# Enable bucket encryption (explicit, even if default)

# Create DynamoDB table (LockID as partition key, PAY_PER_REQUEST billing)

# Verify resources exist (call check function again)

# Print success message with:
#   - Bucket name and region
#   - DynamoDB table name
#   - Next step: "Add these to backend.tf in your Terraform config"
#   - Example backend config snippet
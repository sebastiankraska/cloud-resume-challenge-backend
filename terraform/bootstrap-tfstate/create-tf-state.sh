#!/bin/bash

set -euo pipefail

# Variables at top (bucket name, region, table name)
BUCKET="crc-terraform-state"
REGION="eu-central-1"
TABLE="crc-terraform-lock"

# Test AWS connection (aws sts get-caller-identity)
echo "aws sts get-caller-identity"

# Function: check_resources_exist()
#   - Tests if bucket exists
#   - Tests if DynamoDB table exists  
#   - Returns: 0=both exist, 1=bucket missing, 2=table missing, 3=both missing
function check_resources_exist() {
    if [[ -z "$resource_type" ]] || [[ -z "$resource_name" ]]; then
        echo "Error: --type and --name are required" >&2
        return 1
    fi
}



# Check if resources already exist (call function)
aws dynamodb describe-table --table-name "$TABLE" --region "$REGION"

BUCKETS_BEFORE="$(aws s3 ls)"
if echo "$BUCKETS_BEFORE" | grep -qw "$BUCKET"; then # w = word boundaries = makes grep explicitly look for the whole bucket name
    echo "Bucket '$BUCKET' exists"
else
    echo "Bucket '$BUCKET' does not exist"
fi
check_resources_exist --type "s3" --name "$BUCKET"
check_resources_exist --type "dynamodb" --name "$TABLE"

# If resources exist: inform user and exit
# If partial: warn and exit (manual cleanup required)
# If none exist: proceed

# Show what will be created and ask for confirmation

# Create bucket (handle us-east-1 vs other regions)

# Enable bucket versioning

# Enable bucket encryption (explicit, even if default)

# Create DynamoDB table (LockID as partition key, PAY_PER_REQUEST billing)

# Verify resources exist (call check function again)

# Print success message with:
#   - Bucket name and region
#   - DynamoDB table name
#   - Next step: "Add these to backend.tf in your Terraform config"
#   - Example backend config snippet
#!/bin/bash

# Variables at top (bucket name, region, table name)

# Function: check_resources_exist()
#   - Tests if bucket exists
#   - Tests if DynamoDB table exists  
#   - Returns: 0=both exist, 1=bucket missing, 2=table missing, 3=both missing

# Test AWS connection (aws sts get-caller-identity)

# Check if resources already exist (call function)

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
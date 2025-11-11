resource "aws_dynamodb_table" "cloudresumechallenge" {
  name         = var.dynamo_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

output "dynmodb_table_arn" {
  value       = aws_dynamodb_table.cloudresumechallenge.arn
  description = "DynamoDB table ARN for the Cloud Resume Challenge"
}
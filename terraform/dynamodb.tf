resource "aws_dynamodb_table" "visitor_counter" {
  name = var.dynamo_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "site-counter"
  attribute {
    name = "site-counter"
    type = "S"
  }
}

output "dynmodb_table_arn" {
  value = aws_dynamodb_table.visitor_counter.arn
  description = "DynamoDB table ARN for visitor counter"
}
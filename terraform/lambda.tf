
# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "lambda_execution_role_2"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    actions = [
      "dynamodb:UpdateItem",
    ]
    resources = [
      aws_dynamodb_table.cloudresumechallenge.arn
    ]
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name   = "lambda_dynamodb_access"
  role   = aws_iam_role.lambda.name
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

# Package the Lambda function code
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/visit-counter.py"
  output_path = "${path.module}/lambda/visit-counter.zip"
}

# Lambda function
resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "visitor_counter"
  role             = aws_iam_role.lambda.arn
  handler          = "visit-counter.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.13"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME  = var.dynamo_table_name
      ENVIRONMENT          = "PRODUCTION"
      AWS_LAMBDA_LOG_LEVEL = "INFO"
    }
  }

  tags = {
    Environment = "production"
    Application = "visit-counter"
  }
}
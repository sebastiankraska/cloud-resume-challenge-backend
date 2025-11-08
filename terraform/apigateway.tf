resource "aws_apigatewayv2_api" "visitor_counter" {
  name          = "visitor-counter-api"
  protocol_type = "HTTP"
  cors_configuration {
    # allow_origins = ["https://sebastiankraska.com"]
    allow_origins = ["*"] // ONLY for testing
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_route" "get_count" {
  api_id    = aws_apigatewayv2_api.visitor_counter.id
  route_key = "GET /visitor-count"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.visitor_counter.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.lambda.invoke_arn
  payload_format_version = "2.0" // Without this, API Gateway might not know how to handle the Lambda response properly (resulting in "Internal Server Error")
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.visitor_counter.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_counter.execution_arn}/*/*"
}

output "api_endpoint" {
  value = aws_apigatewayv2_stage.prod.invoke_url
}


# resource "aws_apigatewayv2_route" "example" {
#   api_id    = aws_apigatewayv2_api.example.id
#   route_key = "$default"
# }

# resource "aws_lambda_function" "example" {
#   filename      = "example.zip"
#   function_name = "Example"
#   role          = aws_iam_role.example.arn
#   handler       = "index.handler"
#   runtime       = "nodejs20.x"
# }

# resource "aws_apigatewayv2_integration" "example" {
#   api_id           = aws_apigatewayv2_api.example.id
#   integration_type = "AWS_PROXY"

#   connection_type           = "INTERNET"
#   content_handling_strategy = "CONVERT_TO_TEXT"
#   description               = "Lambda example"
#   integration_method        = "POST"
#   integration_uri           = aws_lambda_function.example.invoke_arn
#   passthrough_behavior      = "WHEN_NO_MATCH"
# }

# resource "aws_apigatewayv2_stage" "example" {
#   api_id = aws_apigatewayv2_api.example.id
#   name   = "example-stage"
# }
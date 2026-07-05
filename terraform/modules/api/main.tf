# API Gateway (HTTP API) -> request-upload, protégée par un authorizer JWT Cognito
resource "aws_apigatewayv2_api" "http" {
  name          = "${var.name}-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = var.allowed_origins
    allow_methods = ["GET", "POST", "PATCH", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
  }
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.http.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.name}-cognito-jwt"

  jwt_configuration {
    audience = [var.cognito_audience]
    issuer   = var.cognito_issuer
  }
}

resource "aws_apigatewayv2_integration" "request_upload" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.request_upload_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "request_upload" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /uploads"
  target             = "integrations/${aws_apigatewayv2_integration.request_upload.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# admin-documents : dashboard admin (liste + revue), protégé JWT
resource "aws_apigatewayv2_integration" "admin_documents" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.admin_documents_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "list_documents" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "GET /documents"
  target             = "integrations/${aws_apigatewayv2_integration.admin_documents.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "update_document" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "PATCH /documents/{documentId}"
  target             = "integrations/${aws_apigatewayv2_integration.admin_documents.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.request_upload_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_invoke_admin" {
  statement_id  = "AllowAPIGatewayInvokeAdmin"
  action        = "lambda:InvokeFunction"
  function_name = var.admin_documents_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

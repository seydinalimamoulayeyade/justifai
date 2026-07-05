output "api_endpoint" {
  description = "URL de base de l'API HTTP"
  value       = aws_apigatewayv2_api.http.api_endpoint
}

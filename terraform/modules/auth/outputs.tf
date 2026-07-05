output "user_pool_id" {
  description = "ID du User Pool Cognito"
  value       = aws_cognito_user_pool.main.id
}

output "client_id" {
  description = "ID du client applicatif (SPA) Cognito"
  value       = aws_cognito_user_pool_client.spa.id
}

output "issuer" {
  description = "Issuer JWT du User Pool (pour l'authorizer API Gateway)"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
}

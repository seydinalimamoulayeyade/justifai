output "documents_bucket" {
  description = "Nom du bucket S3 des justificatifs"
  value       = module.storage.bucket_name
}

output "documents_table" {
  description = "Nom de la table DynamoDB"
  value       = module.storage.table_name
}

output "api_endpoint" {
  description = "URL de base de l'API HTTP"
  value       = module.api.api_endpoint
}

output "notifications_topic_arn" {
  description = "ARN du topic SNS de notification"
  value       = module.messaging.topic_arn
}

output "cognito_user_pool_id" {
  description = "ID du User Pool Cognito"
  value       = module.auth.user_pool_id
}

output "cognito_client_id" {
  description = "ID du client applicatif (SPA) Cognito"
  value       = module.auth.client_id
}

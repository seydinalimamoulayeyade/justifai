output "documents_bucket" {
  description = "Nom du bucket S3 des justificatifs"
  value       = aws_s3_bucket.documents.bucket
}

output "documents_table" {
  description = "Nom de la table DynamoDB"
  value       = aws_dynamodb_table.documents.name
}

output "api_endpoint" {
  description = "URL de base de l'API HTTP"
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "notifications_topic_arn" {
  description = "ARN du topic SNS de notification"
  value       = aws_sns_topic.notifications.arn
}

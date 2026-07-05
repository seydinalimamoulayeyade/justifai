output "bucket_id" {
  description = "ID du bucket S3 des justificatifs"
  value       = aws_s3_bucket.documents.id
}

output "bucket_arn" {
  description = "ARN du bucket S3"
  value       = aws_s3_bucket.documents.arn
}

output "bucket_name" {
  description = "Nom du bucket S3"
  value       = aws_s3_bucket.documents.bucket
}

output "table_name" {
  description = "Nom de la table DynamoDB"
  value       = aws_dynamodb_table.documents.name
}

output "table_arn" {
  description = "ARN de la table DynamoDB"
  value       = aws_dynamodb_table.documents.arn
}

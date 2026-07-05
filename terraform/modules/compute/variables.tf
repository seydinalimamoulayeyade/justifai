variable "name" {
  description = "Préfixe de nommage des ressources"
  type        = string
}

variable "lambda_source_base" {
  description = "Chemin du dossier racine des sources Lambda"
  type        = string
}

variable "build_dir" {
  description = "Dossier de sortie des archives zip"
  type        = string
}

variable "bucket_id" {
  description = "ID du bucket S3 des justificatifs"
  type        = string
}

variable "bucket_arn" {
  description = "ARN du bucket S3"
  type        = string
}

variable "bucket_name" {
  description = "Nom du bucket S3"
  type        = string
}

variable "table_name" {
  description = "Nom de la table DynamoDB"
  type        = string
}

variable "table_arn" {
  description = "ARN de la table DynamoDB"
  type        = string
}

variable "queue_arn" {
  description = "ARN de la file SQS de notification"
  type        = string
}

variable "queue_url" {
  description = "URL de la file SQS de notification"
  type        = string
}

variable "topic_arn" {
  description = "ARN du topic SNS de notification"
  type        = string
}

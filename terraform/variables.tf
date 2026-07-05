variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Préfixe de nommage des ressources"
  type        = string
  default     = "justifai"
}

variable "environment" {
  description = "Environnement (dev, prod, ...)"
  type        = string
  default     = "dev"
}

variable "notification_email" {
  description = "Email abonné au topic SNS de notification"
  type        = string
}

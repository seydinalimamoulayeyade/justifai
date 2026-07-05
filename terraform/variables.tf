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

variable "allowed_origins" {
  description = "Origines autorisées par le CORS de l'API (front)"
  type        = list(string)
  default     = ["http://localhost:5173"]
}

variable "alarm_email" {
  description = "Email destinataire des alarmes CloudWatch (vide = pas d'abonnement)"
  type        = string
  default     = ""
}

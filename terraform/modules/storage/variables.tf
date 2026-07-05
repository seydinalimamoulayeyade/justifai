variable "name" {
  description = "Préfixe de nommage des ressources"
  type        = string
}

variable "account_id" {
  description = "ID du compte AWS (unicité du nom de bucket)"
  type        = string
}

variable "allowed_origins" {
  description = "Origines autorisées pour l'upload navigateur (CORS S3, PUT présigné)"
  type        = list(string)
}

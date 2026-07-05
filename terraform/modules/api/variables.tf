variable "name" {
  description = "Préfixe de nommage des ressources"
  type        = string
}

variable "allowed_origins" {
  description = "Origines autorisées par le CORS de l'API"
  type        = list(string)
}

variable "request_upload_invoke_arn" {
  description = "Invoke ARN de la Lambda request-upload"
  type        = string
}

variable "request_upload_function_name" {
  description = "Nom de la Lambda request-upload"
  type        = string
}

variable "admin_documents_invoke_arn" {
  description = "Invoke ARN de la Lambda admin-documents"
  type        = string
}

variable "admin_documents_function_name" {
  description = "Nom de la Lambda admin-documents"
  type        = string
}

variable "cognito_issuer" {
  description = "Issuer JWT du User Pool Cognito"
  type        = string
}

variable "cognito_audience" {
  description = "Audience JWT (client ID Cognito)"
  type        = string
}

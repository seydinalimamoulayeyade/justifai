output "request_upload_invoke_arn" {
  description = "Invoke ARN de la Lambda request-upload (intégration API Gateway)"
  value       = aws_lambda_function.request_upload.invoke_arn
}

output "request_upload_function_name" {
  description = "Nom de la Lambda request-upload"
  value       = aws_lambda_function.request_upload.function_name
}

output "function_names" {
  description = "Noms des Lambdas, indexés par clé logique (pour l'observabilité)"
  value = {
    request_upload   = aws_lambda_function.request_upload.function_name
    process_document = aws_lambda_function.process_document.function_name
    notify           = aws_lambda_function.notify.function_name
  }
}

locals {
  name = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Câblage des modules
# ---------------------------------------------------------------------------
module "storage" {
  source     = "./modules/storage"
  name       = local.name
  account_id = data.aws_caller_identity.current.account_id
}

module "messaging" {
  source             = "./modules/messaging"
  name               = local.name
  notification_email = var.notification_email
}

module "auth" {
  source     = "./modules/auth"
  name       = local.name
  aws_region = var.aws_region
}

module "compute" {
  source             = "./modules/compute"
  name               = local.name
  lambda_source_base = "${path.module}/../backend/lambdas"
  build_dir          = "${path.module}/build"

  bucket_id   = module.storage.bucket_id
  bucket_arn  = module.storage.bucket_arn
  bucket_name = module.storage.bucket_name
  table_name  = module.storage.table_name
  table_arn   = module.storage.table_arn
  queue_arn   = module.messaging.queue_arn
  queue_url   = module.messaging.queue_url
  topic_arn   = module.messaging.topic_arn
}

module "api" {
  source          = "./modules/api"
  name            = local.name
  allowed_origins = var.allowed_origins

  request_upload_invoke_arn    = module.compute.request_upload_invoke_arn
  request_upload_function_name = module.compute.request_upload_function_name
  cognito_issuer               = module.auth.issuer
  cognito_audience             = module.auth.client_id
}

module "monitoring" {
  source         = "./modules/monitoring"
  name           = local.name
  alarm_email    = var.alarm_email
  function_names = module.compute.function_names
  dlq_name       = module.messaging.dlq_name
}

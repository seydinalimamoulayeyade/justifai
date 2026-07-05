locals {
  name = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Stockage : S3 (justificatifs) + DynamoDB (statuts)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "documents" {
  bucket = "${local.name}-documents-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket                  = aws_s3_bucket.documents.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "documents" {
  name         = "${local.name}-documents"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "documentId"

  attribute {
    name = "documentId"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}

# ---------------------------------------------------------------------------
# Messagerie : SNS (email) + SQS (+ DLQ)
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "notifications" {
  name = "${local.name}-notifications"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sqs_queue" "dlq" {
  name = "${local.name}-notify-dlq"
}

resource "aws_sqs_queue" "notify" {
  name = "${local.name}-notify"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# ---------------------------------------------------------------------------
# Packaging des Lambdas (zip à partir des sources)
# ---------------------------------------------------------------------------
data "archive_file" "request_upload" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/lambdas/request-upload"
  output_path = "${path.module}/build/request-upload.zip"
}

data "archive_file" "process_document" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/lambdas/process-document"
  output_path = "${path.module}/build/process-document.zip"
}

data "archive_file" "notify" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/lambdas/notify"
  output_path = "${path.module}/build/notify.zip"
}

# ---------------------------------------------------------------------------
# IAM : rôle d'exécution commun + politiques (least-privilege)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "request_upload" {
  name               = "${local.name}-request-upload"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role" "process_document" {
  name               = "${local.name}-process-document"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role" "notify" {
  name               = "${local.name}-notify"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Logs CloudWatch pour toutes les Lambdas
resource "aws_iam_role_policy_attachment" "logs" {
  for_each   = toset([aws_iam_role.request_upload.name, aws_iam_role.process_document.name, aws_iam_role.notify.name])
  role       = each.value
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# request-upload : générer une URL présignée (PUT sur le bucket)
resource "aws_iam_role_policy" "request_upload" {
  name = "s3-put"
  role = aws_iam_role.request_upload.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = "${aws_s3_bucket.documents.arn}/*"
    }]
  })
}

# process-document : lire S3, Textract, écrire DynamoDB, envoyer SQS
resource "aws_iam_role_policy" "process_document" {
  name = "process"
  role = aws_iam_role.process_document.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.documents.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["textract:DetectDocumentText", "textract:AnalyzeDocument"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.documents.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.notify.arn
      }
    ]
  })
}

# notify : consommer SQS, publier SNS
resource "aws_iam_role_policy" "notify" {
  name = "notify"
  role = aws_iam_role.notify.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = aws_sqs_queue.notify.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.notifications.arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Lambdas
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "request_upload" {
  function_name    = "${local.name}-request-upload"
  role             = aws_iam_role.request_upload.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.request_upload.output_path
  source_code_hash = data.archive_file.request_upload.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      BUCKET = aws_s3_bucket.documents.bucket
    }
  }
}

resource "aws_lambda_function" "process_document" {
  function_name    = "${local.name}-process-document"
  role             = aws_iam_role.process_document.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.process_document.output_path
  source_code_hash = data.archive_file.process_document.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      TABLE     = aws_dynamodb_table.documents.name
      QUEUE_URL = aws_sqs_queue.notify.url
    }
  }
}

resource "aws_lambda_function" "notify" {
  function_name    = "${local.name}-notify"
  role             = aws_iam_role.notify.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.notify.output_path
  source_code_hash = data.archive_file.notify.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.notifications.arn
    }
  }
}

# ---------------------------------------------------------------------------
# Déclencheurs
# ---------------------------------------------------------------------------
# S3 -> process-document
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_document.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.documents.arn
}

resource "aws_s3_bucket_notification" "documents" {
  bucket = aws_s3_bucket.documents.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.process_document.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.s3_invoke]
}

# SQS -> notify
resource "aws_lambda_event_source_mapping" "notify" {
  event_source_arn = aws_sqs_queue.notify.arn
  function_name    = aws_lambda_function.notify.arn
  batch_size       = 5
}

# ---------------------------------------------------------------------------
# API Gateway (HTTP API) -> request-upload
# TODO: ajouter un authorizer JWT Cognito devant les routes.
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
  }
}

resource "aws_apigatewayv2_integration" "request_upload" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.request_upload.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "request_upload" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /uploads"
  target    = "integrations/${aws_apigatewayv2_integration.request_upload.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.request_upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

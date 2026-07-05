# ---------------------------------------------------------------------------
# Packaging des Lambdas (zip à partir des sources)
# ---------------------------------------------------------------------------
data "archive_file" "request_upload" {
  type        = "zip"
  source_dir  = "${var.lambda_source_base}/request-upload"
  output_path = "${var.build_dir}/request-upload.zip"
}

data "archive_file" "process_document" {
  type        = "zip"
  source_dir  = "${var.lambda_source_base}/process-document"
  output_path = "${var.build_dir}/process-document.zip"
}

data "archive_file" "notify" {
  type        = "zip"
  source_dir  = "${var.lambda_source_base}/notify"
  output_path = "${var.build_dir}/notify.zip"
}

data "archive_file" "admin_documents" {
  type        = "zip"
  source_dir  = "${var.lambda_source_base}/admin-documents"
  output_path = "${var.build_dir}/admin-documents.zip"
}

# ---------------------------------------------------------------------------
# IAM : un rôle par Lambda (least-privilege)
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
  name               = "${var.name}-request-upload"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role" "process_document" {
  name               = "${var.name}-process-document"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role" "notify" {
  name               = "${var.name}-notify"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role" "admin_documents" {
  name               = "${var.name}-admin-documents"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Logs CloudWatch pour toutes les Lambdas
resource "aws_iam_role_policy_attachment" "logs" {
  for_each   = toset([aws_iam_role.request_upload.name, aws_iam_role.process_document.name, aws_iam_role.notify.name, aws_iam_role.admin_documents.name])
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
      Resource = "${var.bucket_arn}/*"
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
        Resource = "${var.bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["textract:DetectDocumentText", "textract:AnalyzeDocument"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
        Resource = var.table_arn
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = var.queue_arn
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
        Resource = var.queue_arn
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.topic_arn
      }
    ]
  })
}

# admin-documents : requêter par statut (GSI) + mettre à jour un document
resource "aws_iam_role_policy" "admin_documents" {
  name = "admin-documents"
  role = aws_iam_role.admin_documents.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Query"]
        Resource = "${var.table_arn}/index/*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:UpdateItem", "dynamodb:GetItem"]
        Resource = var.table_arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Lambdas
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "request_upload" {
  function_name    = "${var.name}-request-upload"
  role             = aws_iam_role.request_upload.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.request_upload.output_path
  source_code_hash = data.archive_file.request_upload.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      BUCKET = var.bucket_name
    }
  }
}

resource "aws_lambda_function" "process_document" {
  function_name    = "${var.name}-process-document"
  role             = aws_iam_role.process_document.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.process_document.output_path
  source_code_hash = data.archive_file.process_document.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      TABLE     = var.table_name
      QUEUE_URL = var.queue_url
    }
  }
}

resource "aws_lambda_function" "notify" {
  function_name    = "${var.name}-notify"
  role             = aws_iam_role.notify.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.notify.output_path
  source_code_hash = data.archive_file.notify.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TOPIC_ARN = var.topic_arn
    }
  }
}

resource "aws_lambda_function" "admin_documents" {
  function_name    = "${var.name}-admin-documents"
  role             = aws_iam_role.admin_documents.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.admin_documents.output_path
  source_code_hash = data.archive_file.admin_documents.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE        = var.table_name
      STATUS_INDEX = "status-index"
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
  source_arn    = var.bucket_arn
}

resource "aws_s3_bucket_notification" "documents" {
  bucket = var.bucket_id
  lambda_function {
    lambda_function_arn = aws_lambda_function.process_document.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.s3_invoke]
}

# SQS -> notify
resource "aws_lambda_event_source_mapping" "notify" {
  event_source_arn = var.queue_arn
  function_name    = aws_lambda_function.notify.arn
  batch_size       = 5
}

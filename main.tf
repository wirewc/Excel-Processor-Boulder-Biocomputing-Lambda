# ------------------------------------------------------------------------------
# Lambda Module — Excel Lambda × BBC Databridge
#
# Purpose:
#   Deploys the Boulder Biocomputing provided Excel processing Lambda (excelproc-xlxf-lambda.zip)
#   into the host AWS account with least-privilege IAM permissions:
#     - Read and write to the s3 bucket (bbc-databridge)
#     - Read excelproc/bbc-config from Secrets Manager (Dotmatics credentials)
#
# Deployment:
#   1. Place excelproc-xlxf-lambda.zip in the project root (one level above terraform/).
#   2. Run: terraform apply
#
# Validation:
#   - Upload a .xlsx file to s3://bbc-databridge/upload/ and confirm
#     the Lambda invocation appears in CloudWatch Logs:
#     /aws/lambda/bbc-excel-processor
#
# Troubleshooting:
#   - "Unable to import module": verify lambda_handler matches the zip's entry
#     point (default: lambda_function.lambda_handler).
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/bbc-excel-processor"
  retention_in_days = 30
  tags              = var.tags
}

# ---------------------------------------------------------------------------
# IAM — Lambda execution role
# ---------------------------------------------------------------------------

resource "aws_iam_role" "lambda_exec" {
  name = "bbc-lambda-execution-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Managed policy: write CloudWatch Logs
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Inline policy: S3 — read and write to the s3 bucket (bbc-databridge) and exclude upload/ prefix to prevent infinite trigger loops.
resource "aws_iam_role_policy" "s3_access" {
  name = "bbc-lambda-s3-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowListDatabridge"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = ["arn:aws:s3:::${var.bucket_name}"]
      },
      {
        Sid      = "AllowGetFromUpload"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::${var.bucket_name}/upload/*"]
      },
      {
        Sid    = "AllowPutToOutputPrefixes"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*",
        ]
      }
    ]
  })
}

# Inline policy: Secrets Manager — read Dotmatics credentials at runtime
resource "aws_iam_role_policy" "secrets_access" {
  name = "bbc-lambda-secrets-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "ReadDotmaticsConfig"
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [var.secret_arn]
    }]
  })
}

# ---------------------------------------------------------------------------
# Lambda function
# ---------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  function_name = "bbc-excel-processor"
  description   = "Processes Excel files from upload/ and writes results to output prefixes in bbc-databridge"
  architectures = ["x86_64"]
  filename      = var.lambda_zip_path
  role          = aws_iam_role.lambda_exec.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  timeout       = 900
  memory_size   = 1024

  # Forces re-deploy when the zip changes
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  environment {
    variables = {
      S3_BUCKET_NAME = var.bucket_name
      SECRET_ARN     = var.secret_arn
      SECRET_NAME    = var.secret_name
    }
  }

  tags = var.tags

  # Ensure log group exists before first invocation so retention is enforced
  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.basic_execution,
  ]
}

# Allow S3 to invoke the Lambda on upload/ PutObject events
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket_name}"
}

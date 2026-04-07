variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the shared S3 databridge bucket"
  type        = string
}

variable "secret_arn" {
  description = "ARN of the excelproc/bbc-config Secrets Manager secret"
  type        = string
}

variable "secret_name" {
  description = "Secrets Manager secret name (exposed as SECRET_NAME to the Lambda)"
  type        = string
  default     = "excelproc/bbc-config"
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment zip file (excelproc-xlxf-lambda.zip)"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime identifier (e.g. python3.14)"
  type        = string
  default     = "python3.14"
}

variable "lambda_handler" {
  description = "Lambda handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

variable "security_group_ids" {
  description = "Security group ID"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

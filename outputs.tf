output "function_arn" {
  description = "ARN of the deployed Lambda function (bbc-excel-processor)"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_exec.arn
}

output "backend_state" {
  value       = aws_s3_bucket.s3.id
  description = "The S3 bucket used for Terraform backend state storage"
}
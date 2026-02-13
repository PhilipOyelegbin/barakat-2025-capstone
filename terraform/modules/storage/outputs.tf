output "output_details" {
  description = "Details of storage resources created."
  value = {
    bucket_name = aws_s3_bucket.assets_bucket.bucket
  }
}

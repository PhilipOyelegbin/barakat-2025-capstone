#============================================ Serverless S3 Bucket ============================================
# S3 Bucket for Assets
resource "aws_s3_bucket" "assets_bucket" {
  bucket = "${var.project_name}-assets-altsoe0251574"

  tags = {
    Name    = "${var.project_name}-assets-altsoe0251574"
    Project = var.project_tag
  }
}

# Block public access to the Assets bucket
resource "aws_s3_bucket_public_access_block" "assets_block_public_access" {
  bucket                  = aws_s3_bucket.assets_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Disable versioning for Assets bucket
resource "aws_s3_bucket_versioning" "assets_versioning" {
  bucket = aws_s3_bucket.assets_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

# Enable default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "assets_encryption" {
  bucket = aws_s3_bucket.assets_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#============================================ Serverless Lambda ============================================
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.js"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda execution
resource "aws_lambda_function" "bedrock_asset_processor" {
  function_name = "${var.project_name}-asset-processor"
  role = var.lambda_role_arn
  runtime = "nodejs22.x"
  handler = "lambda_function.handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [
    var.lambda_role_arn
  ]
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bedrock_asset_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.assets_bucket.arn
}

# S3 bucket notification to trigger Lambda on object creation
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.assets_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.bedrock_asset_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [
    aws_lambda_permission.allow_s3
  ]
}

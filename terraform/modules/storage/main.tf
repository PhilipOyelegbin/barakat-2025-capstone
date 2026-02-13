#============================================ S3 Bucket ============================================#
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

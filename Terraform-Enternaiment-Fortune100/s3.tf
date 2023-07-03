# s3.tf


resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.app_name}-${var.app_environment}"

  tags = {
    Name        = "${var.app_name}-s3-bucket"
    Environment = var.app_environment
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["Content-Disposition"]
  }
}

# resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption" {
#   bucket = aws_s3_bucket.s3_bucket.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm     = "AES256"
#     }
#   }
# }


resource "aws_s3_bucket_public_access_block" "s3_access_block" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_lifecycle_configuration" "migrate_files_to_intelligent_tiering" {

#   bucket = aws_s3_bucket.s3_bucket.bucket

#   rule {
#     id = "migrate-files-to-intelligent-tiering"
#     status = "Enabled"

#     expiration {
#       days          = 14
#     }

#     transition {
#       storage_class = "INTELLIGENT_TIERING"
#     }
#   }
# }
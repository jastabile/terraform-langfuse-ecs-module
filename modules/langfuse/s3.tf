resource "aws_s3_bucket" "langfuse" {
  bucket = var.s3_bucket_name

  # Add tags for better resource management
  tags = {
    Name    = var.s3_bucket_name
    Domain  = var.domain
    Service = "langfuse"
  }
}

resource "aws_s3_bucket_versioning" "langfuse" {
  bucket = aws_s3_bucket.langfuse.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "langfuse" {
  bucket = aws_s3_bucket.langfuse.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add lifecycle rules for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "langfuse" {
  bucket = aws_s3_bucket.langfuse.id

  # https://aws.amazon.com/s3/storage-classes/
  # Transition to "STANDARD Infrequent Access" after 90 days, and
  # to "GLACIER Instant Retrieval" after 180 days
  rule {
    id     = "langfuse_lifecycle"
    status = "Enabled"

    filter {
      prefix = "" # Empty prefix matches all objects
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER_IR"
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

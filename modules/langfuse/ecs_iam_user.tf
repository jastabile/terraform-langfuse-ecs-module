resource "aws_iam_user" "langfuse_s3" {
  name = "${var.name}-langfuse-s3"
}

resource "aws_iam_access_key" "langfuse_s3" {
  user = aws_iam_user.langfuse_s3.name
}

resource "aws_iam_user_policy" "langfuse_s3" {
  name = "${var.name}-langfuse-s3-policy"
  user = aws_iam_user.langfuse_s3.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.langfuse.arn,
          "${aws_s3_bucket.langfuse.arn}/*"
        ]
      }
    ]
  })
}

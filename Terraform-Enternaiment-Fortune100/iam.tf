# iam.tf | IAM Role Policies

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.app_name}-execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name        = "${var.app_name}-ecs-task-execution-role"
    Environment = var.app_environment
  }
}

resource "aws_iam_role" "ecsTaskRole" {
  name               = "${var.app_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name        = "${var.app_name}-ecs-task-role"
    Environment = var.app_environment
  }
}

resource "aws_iam_role" "ecsTaskRole_direct_upload" {
  name               = "${var.app_name}-task-role-direct-upload"
  assume_role_policy = data.aws_iam_policy_document.assume_role_direct_upload_policy.json
  tags = {
    Name        = "${var.app_name}-ecs-task-role-direct-uploa"
    Environment = var.app_environment
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assume_role_direct_upload_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.ecsTaskRole.arn}"]
    }
  }
}

data "aws_iam_policy_document" "s3_policy_doc" {
  statement {
    sid       = "s3GetBucket"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}"]

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:ListBucketMultipartUploads",
      "s3:GetBucketObjectLockConfiguration",
    ]
  }

  statement {
    sid       = "s3readWriteDelete"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}/*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:PutObjectRetention",
      "s3:PutObjectLegalHold"
    ]
  }
}

resource "aws_iam_policy" "s3" {
  name        = "${var.app_name}-task-policy-s3"
  description = "Policy that allows access to S3"
  policy      = data.aws_iam_policy_document.s3_policy_doc.json
}

resource "aws_iam_policy" "s3_direct_upload" {
  name        = "${var.app_name}-task-policy-s3-direct-upload"
  description = "Policy that allows access to direct upload S3"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:GetBucketVersioning",
                "s3:ListBucketMultipartUploads",
                "s3:GetBucketObjectLockConfiguration"
            ],
            "Resource": "arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectAttributes",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts",
                "s3:PutObjectRetention",
                "s3:PutObjectLegalHold"
            ],
            "Resource": "arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}/*"
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecsTaskRole_policy" {
  role       = aws_iam_role.ecsTaskRole.name
  policy_arn = aws_iam_policy.s3.arn
}
resource "aws_iam_role_policy_attachment" "ecsTaskRole_s3_direct_upload_policy" {
  role       = aws_iam_role.ecsTaskRole_direct_upload.name
  policy_arn = aws_iam_policy.s3_direct_upload.arn
}
data "aws_iam_policy_document" "s3_ecr_access" {
  version = "2012-10-17"
  statement {
    sid       = "s3access"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::prod-${var.aws_region}-starport-layer-bucket/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
  statement {
    sid       = "s3appBucketObjects"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
  statement {
    sid       = "s3appBucket"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }


}

# ECR endpoint policy
data "aws_iam_policy_document" "ecr_vpc_endpoint" {
  statement {
    sid       = "AllowAll"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "PreventDelete"
    effect    = "Deny"
    resources = ["${var.ecr_arn}"]
    actions   = ["ecr:DeleteRepository"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "AllowPull"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetAuthorizationToken",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}



data "aws_caller_identity" "current" {}

locals {
    account_id = data.aws_caller_identity.current.account_id
}

resource "aws_security_group" "opensearch_security_group" {
  name        = "${var.app_name}-engine-sg"
  vpc_id      = aws_vpc.aws-vpc.id
  description = "HTTP from ECS Task Subgroup"

  ingress {
    description = "HTTP from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.service_security_group.id]
  }
}

resource "aws_cloudwatch_log_group" "opensearch_log_group_index_slow_logs" {
  name              = "/aws/opensearch/${var.app_name}-engine/index-slow"
  retention_in_days = var.aws_cloudwatch_retention_in_days
}

resource "aws_cloudwatch_log_group" "opensearch_log_group_search_slow_logs" {
  name              = "/aws/opensearch/${var.app_name}-engine/search-slow"
  retention_in_days = var.aws_cloudwatch_retention_in_days
}

resource "aws_cloudwatch_log_group" "opensearch_log_group_es_application_logs" {
  name              = "/aws/opensearch/${var.app_name}-engine/es-application"
  retention_in_days = var.aws_cloudwatch_retention_in_days
}


resource "aws_cloudwatch_log_resource_policy" "opensearch_log_resource_policy" {
  policy_name = "${var.app_name}-engine-domain-log-resource-policy"

  policy_document = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": [
        "logs:*"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.opensearch_log_group_index_slow_logs.arn}:*",
        "${aws_cloudwatch_log_group.opensearch_log_group_search_slow_logs.arn}:*",
        "${aws_cloudwatch_log_group.opensearch_log_group_es_application_logs.arn}:*"
      ],
      "Condition": {
          "StringEquals": {
              "aws:SourceAccount": "${var.aws_region}"
          },
          "ArnLike": {
              "aws:SourceArn": "arn:aws:es:${var.aws_region}:${local.account_id}:domain/${var.app_name}-engine"
          }
      }
    }
  ]
}
CONFIG
}

resource "aws_opensearch_domain" "opensearch" {
  domain_name    = "${var.app_name}-engine"
  engine_version = "${var.es_engine_version}"

  cluster_config {
    dedicated_master_count   = var.es_dedicated_master_count
    dedicated_master_type    = var.es_dedicated_master_type
    dedicated_master_enabled = var.es_dedicated_master_enabled
    instance_type            = var.es_instance_type
    instance_count           = var.es_instance_count
    zone_awareness_enabled   = var.es_instance_count > 1
    zone_awareness_config {
      availability_zone_count = var.es_instance_count > 1 ? length(aws_subnet.private.*.id) : null
    }
  }

  encrypt_at_rest {
    enabled = var.es_node_to_node_encryption
  }

  ebs_options {
    ebs_enabled = var.es_ebs_enabled
    volume_size = var.es_ebs_volume_size
    volume_type = var.es_volume_type
    throughput  = var.es_throughput
  }

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    subnet_ids = var.es_instance_count > 1? tolist(aws_subnet.private.*.id) : [aws_subnet.private[0].id] 
    security_group_ids = [aws_security_group.opensearch_security_group.id]
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${var.aws_region}:${local.account_id}:domain/${var.app_name}-engine/*"
        }
    ]
}
CONFIG
}


resource "aws_s3_bucket_object" "synonyms_file_3" {
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "synonyms_cli_3.txt"
  source = "${path.module}/synonyms_cli_3.txt"
}

resource "null_resource" "create_package" {
  provisioner "local-exec" {
    command = <<EOT
      aws es create-package --package-name ${var.es_package_name} --package-type TXT-DICTIONARY --package-source  S3BucketName=${aws_s3_bucket.s3_bucket.bucket},S3Key=${aws_s3_bucket_object.synonyms_file_3.key}
    EOT
  }
}

resource "null_resource" "associate_package" {
  depends_on = [null_resource.create_package]

  provisioner "local-exec" {
    command = "associate_package.sh ${var.es_package_name} ${aws_opensearch_domain.opensearch.domain_name}"
  }
}

data "external" "package_id" {
  program = ["sh", "-c",  "aws es describe-packages --filters 'Name=PackageName,Value=${var.es_package_name}' | jq -r '.PackageDetailsList[0]'"]
}

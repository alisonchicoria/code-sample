resource "aws_security_group" "msk-prometheus-sg" {
  name        = "${var.msk_cluster_name}-prometheus"
  description = "Security group for Prometheus"
  vpc_id      = aws_vpc.aws-vpc.id

  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    self        = true
  }

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    self        = true
  }

  ingress {
    from_port   = 2182
    to_port     = 2182
    protocol    = "tcp"
    self        = true
  }

  ingress {
    from_port   = 11001
    to_port     = 11001
    protocol    = "tcp"
    self        = var.msk_prometheus_jmx_exporter ? true : false
  }

  ingress {
    from_port   = 11002
    to_port     = 11002
    protocol    = "tcp"
    self        = var.msk_prometheus_node_exporter ? true : false
  }  

}

resource "aws_security_group" "msk-sg" {
  name_prefix = "${var.msk_cluster_name}-"
  vpc_id      = aws_vpc.aws-vpc.id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    self        = true
    security_groups = [aws_security_group.service_security_group.id]
  }
}

resource "aws_cloudwatch_log_group" "msk_logs" {
  name              = "/aws/msk/${var.app_name}/logs"
  retention_in_days = var.aws_cloudwatch_retention_in_days
}

resource "aws_msk_configuration" "this" {
  kafka_versions    = [var.msk_kafka_version]
  name              = var.msk_cluster_name
  server_properties = <<PROPERTIES
auto.create.topics.enable = true
delete.topic.enable = true
default.replication.factor = ${var.msk_kafka_replication_factor}
PROPERTIES

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_msk_cluster" "this" {
  depends_on = [aws_msk_configuration.this]

  cluster_name           = var.msk_cluster_name
  kafka_version          = var.msk_kafka_version
  number_of_broker_nodes = var.msk_number_of_brokers
  enhanced_monitoring    = var.msk_enhanced_monitoring

  broker_node_group_info {
    client_subnets  = tolist(aws_subnet.private.*.id)
    instance_type   = var.msk_instance_type
    security_groups = [aws_security_group.msk-sg.id, aws_security_group.msk-prometheus-sg.id]

    storage_info {
      ebs_storage_info {
        volume_size = var.msk_volume_size

        provisioned_throughput {
          enabled           = var.msk_provisioned_volume_throughput == null ? false : true
          volume_throughput = var.msk_provisioned_volume_throughput
        }
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.this.arn
    revision = aws_msk_configuration.this.latest_revision
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = var.msk_encryption_at_rest_kms_key_arn
    encryption_in_transit {
      client_broker = var.msk_encryption_in_transit_client_broker
      in_cluster    = var.msk_encryption_in_transit_in_cluster
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = var.msk_prometheus_jmx_exporter
      }
      node_exporter {
        enabled_in_broker = var.msk_prometheus_node_exporter
      }
    }
  }

  logging_info {
      broker_logs {
        cloudwatch_logs {
          enabled   = true
          log_group = aws_cloudwatch_log_group.msk_logs.name
        }
      }
  }

  tags = {
    Name        = "${var.app_name}-msk"
    Environment = var.app_environment
  }
}
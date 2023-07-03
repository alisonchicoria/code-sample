# ecs.tf | Elastic Container Service Cluster and Tasks Configuration

provider "aws" {
  region = "us-west-2"
}

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-${var.app_environment}-cluster"
  tags = {
    Name        = "${var.app_name}-ecs"
    Environment = var.app_environment
  }
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.app_name}-${var.app_environment}-logs"
  retention_in_days = var.aws_cloudwatch_retention_in_days
  tags = {
    Application = var.app_name
    Environment = var.app_environment
  }
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.app_name}-task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.app_name}-${var.app_environment}-container",
      "image": "${var.ecr_repository_url}:${var.image_tag}",
      "entryPoint": [],
      "environment": [
          {
              "name": "NUXEO_PACKAGES",
              "value": "nuxeo-amazon-s3-package*.zip"
          },
          {
              "name": "S3_BUCKET",
              "value": "${aws_s3_bucket.s3_bucket.bucket}"
          },
          {
              "name": "S3_TRANSIENT_ROLE_ARN",
              "value": "${aws_iam_role.ecsTaskRole_direct_upload.arn}"
          },
          {         
              "name": "MONGODB_SERVER_URI",
              "value": "mongodb://${var.mongo_database_username}:${var.mongo_database_password}@${aws_instance.mongodb-cluster[0].private_ip}:27017,${aws_instance.mongodb-cluster[1].private_ip}:27017/admin?replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=true&w=majority"              
          },
          {         
              "name": "ELASTICSEARCH_URL",
              "value": "https://${aws_opensearch_domain.opensearch.endpoint}"            
          },
          {         
              "name": "ELASTICSEARCH_REPLICAS",
              "value": "${var.es_replicas}"            
          },
          {         
              "name": "ELASTICSEARCH_SHARDS",
              "value": "${var.es_shards}"            
          },
          {         
              "name": "ES_SYNONYM_PACKAGE",
              "value": "analyzers/${data.external.package_id.result["PackageID"]}"            
          },          
          {
              "name": "KAFKA_REPLICATION_FACTOR",
              "value": "${var.msk_kafka_replication_factor}"
          },
          {
              "name": "KAFKA_BOOTSTRAP_SERVERS",
              "value": "${aws_msk_cluster.this.bootstrap_brokers}"
          }          

      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.app_name}-${var.app_environment}"
        }
      },
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      "cpu": 2048,
      "memory": 4096,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "4096"
  cpu                      = "2048"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskRole.arn

  tags = {
    Name        = "${var.app_name}-ecs-td"
    Environment = var.app_environment
  }
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.app_name}-${var.app_environment}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
    security_groups = [
      aws_security_group.service_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-${var.app_environment}-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.listener]
}

resource "aws_security_group" "service_security_group" {
  vpc_id = aws_vpc.aws-vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.app_name}-service-sg"
    Environment = var.app_environment
  }
}

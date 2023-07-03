data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mongo-role" {
  name               = "mongo_role"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

resource "aws_iam_instance_profile" "mongo-instance-profile" {
  name = "mongo-instance-profile"
  role = aws_iam_role.mongo-role.name
}

resource "aws_iam_role_policy" "ec2-describe-instance-policy" {
  name = "ec2-describe-instance-policy"
  role = aws_iam_role.mongo-role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeTags"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ssm-managed-instance-core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.mongo-role.name
}

resource "aws_instance" "mongodb-cluster" {
  count                       = 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.mongo_instance_type
  subnet_id                   = aws_subnet.private[count.index].id
  vpc_security_group_ids      = [aws_security_group.allow_mongo_db-cluster.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.mongo-instance-profile.id

  # Create and attach EBS volumes
  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp3"
    volume_size = "${var.ebs_mongo_size}"
  }

  tags = {
    Name        = "${var.app_name}-MongoDBCluster-${count.index + 1}"
    Environment = var.app_environment
    Role        = count.index == 0 ? "primary" : "secondary"
    Replset     = count.index == 0 ? "mongo${count.index}.replset.member" : "mongo${count.index}.replset.member"
  }
  user_data = base64encode(templatefile("${path.module}/mongo_userdata.sh", {
    aws_region           = var.aws_region
    mongo_user           = var.mongo_database_username
    mongo_admin_password = var.mongo_database_admin_password
    mongo_password       = var.mongo_database_password
    mongo_database       = "nuxeo"
  }))
}

resource "aws_security_group" "allow_mongo_db-cluster" {
  name        = "MongoDB-Cluster-SG"
  description = "MongoDB Cluster SG "
  vpc_id      = aws_vpc.aws-vpc.id

  ingress {
    description     = "MongoSQL"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.service_security_group.id]
  }

  ingress {
    description = "MongoSQL"
    to_port     = 0
    protocol    = "-1"
    from_port   = 0
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-MongoSQL"
    Environment = var.app_environment
  }
}

output "mongoec2_cluster_connection_string" {
  value = "mongodb://${var.mongo_database_username}:${var.mongo_database_password}@${aws_instance.mongodb-cluster[0].private_ip}:27017,${aws_instance.mongodb-cluster[1].private_ip}:27017"
}
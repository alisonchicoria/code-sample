# variables.tf | Auth and Application variables

variable "aws_key_pair_name" {
  type        = string
  description = "AWS Key Pair Name"
}

variable "ecr_repository_url" {
  type        = string
  description = "ECR repo URL to use"
}
variable "ecr_arn" {
  type        = string
  description = "ECR repo ARN to use"
}

variable "image_tag" {
  type        = string
  description = "ECR image tag"
}

variable "certificate_arn" {
  type        = string
  description = "HTTPS Certificate ARN"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_cloudwatch_retention_in_days" {
  type        = number
  description = "AWS CloudWatch Logs Retention in Days"
  default     = 14
}

variable "app_name" {
  type        = string
  description = "Application Name"
}

variable "app_environment" {
  type        = string
  description = "Application Environment"
}

variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnets"
}

variable "private_subnets" {
  description = "List of private subnets"
}

variable "availability_zones" {
  description = "List of availability zones"
}

###Mongo DB Variable
variable "mongo_database_admin_password" {
  description = "Database Admin Password"
}

variable "mongo_instance_type" {
  description = "Choose instance class for EC2 MongoDB"
  default     = "t3.medium"
}

variable "mongo_database_username" {
  description = "Database Username"
}

variable "mongo_database_password" {
  description = "Database Password"
}

###Opensearch Variable

variable "es_volume_type" {
  description = "Volume type"
  type        = string
  default     = "gp3"
}

variable "es_throughput" {
  description = "Throughput"
  type        = number
}

variable "ebs_mongo_size" {
  description = "Size of EBS for mongodb data mount point"
  default     = "50"
}

variable "es_ebs_enabled" {
  description = "Enable EBS volume"
  type        = bool
  default     = "true"
}

variable "es_ebs_volume_size" {
  description = "EBS volume size"
  type        = number
  default     = 20
}

variable "es_instance_type" {
  description = "Opensearch instance type"
  type        = string
  default     = "t3.small.search"
}

variable "es_instance_count" {
  description = "Opensearch instance count"
  type        = number
  default     = 1
}

variable "es_dedicated_master_enabled" {
  description = "Enable Opensearch master dedicated"
  type        = bool
  default     = false
}

variable "es_dedicated_master_count" {
  description = "Opensearch dedicated master count"
  type        = number
  default     = 0
}

variable "es_dedicated_master_type" {
  description = "Opensearch dedicated master type"
  type        = string
  default     = null
}

variable "es_zone_awareness_enabled" {
  description = "Enable Opensearch zone awareness"
  type        = bool
  default     = true
}

variable "es_engine_version" {
  description = "Engine version"
  type        = string
  default     = "Elasticsearch_7.10"
}

variable "es_node_to_node_encryption" {
  description = "Enable Opensearch node-to-node encryption"
  type        = bool
  default     = true
}

variable "es_replicas" {
  description = "Number of Es Replicas"
  type        = number
  default     = 0
}

variable "es_shards" {
  description = "Number of ES Shards"
  type        = number
  default     = 1
}

variable "es_package_name" {
  description = "Name of Synonym Package"
  type        = string
  default     = "synonyms-test3"
}

### MSK variables

variable "msk_cluster_name" {
  description = "Name of the MSK cluster."
  type        = string
}

variable "msk_kafka_version" {
  description = "Specify the desired Kafka software version."
  type        = string
  default     = "2.6.2"
}

variable "msk_number_of_brokers" {
  description = "The desired total number of broker nodes in the kafka cluster. It must be a multiple of the number of specified client subnets."
  type        = number
  default = 2
}

variable "msk_volume_size" {
  description = "The size in GiB of the EBS volume for the data drive on each broker node."
  type        = number
  default     = 20
}

variable "msk_instance_type" {
  description = "Specify the instance type to use for the kafka brokers. e.g. kafka.m5.large."
  type        = string
}

variable "msk_enhanced_monitoring" {
  description = "Specify the desired enhanced MSK CloudWatch monitoring level to one of three monitoring levels: DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER or PER_TOPIC_PER_PARTITION. See [Monitoring Amazon MSK with Amazon CloudWatch](https://docs.aws.amazon.com/msk/latest/developerguide/monitoring.html)."
  type        = string
  default     = "DEFAULT"
}

variable "msk_prometheus_jmx_exporter" {
  description = "Indicates whether you want to enable or disable the JMX Exporter."
  type        = bool
  default     = false
}

variable "msk_prometheus_node_exporter" {
  description = "Indicates whether you want to enable or disable the Node Exporter."
  type        = bool
  default     = false
}

variable "msk_encryption_in_transit_client_broker" {
  description = "Encryption setting for data in transit between clients and brokers. Valid values: TLS, TLS_PLAINTEXT, and PLAINTEXT. Default value is TLS_PLAINTEXT."
  type        = string
  default     = "PLAINTEXT"
}

variable "msk_encryption_in_transit_in_cluster" {
  description = "Whether data communication among broker nodes is encrypted. Default value: true."
  type        = bool
  default     = true
}

variable "msk_encryption_at_rest_kms_key_arn" {
  description = "You may specify a KMS key short ID or ARN (it will always output an ARN) to use for encrypting your data at rest. If no key is specified, an AWS managed KMS ('aws/msk' managed service) key will be used for encrypting the data at rest."
  type        = string
  default     = ""
}

variable "msk_provisioned_volume_throughput" {
  description = "Throughput value of the EBS volumes for the data drive on each kafka broker node in MiB per second. The minimum value is 250. The maximum value varies between broker type. See [https://docs.aws.amazon.com/msk/latest/developerguide/msk-provision-throughput.html#throughput-bottlenecks](documentation on throughput bottlenecks)."
  type        = number
  default     = null
}

variable "msk_kafka_replication_factor" {
  description = "The desired replication factor for Kafka topics."
  type        = number
  default     = 1
}

# main.tf | Main Configuration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }

  backend "s3" {
    bucket = "customer-terraform-state-nuxeo"
    key    = "state/terraform_state.tfstate"
    region = "us-west-2"
  }
}

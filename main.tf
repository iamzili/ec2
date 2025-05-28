variable aws_region {
    default = "us-east-1"
    description = "AWS region where the resources will be provisioned"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure region and profile
provider "aws" {
  region = var.aws_region
}

module "base" {
  source = "./modules/base"
}

module "dashboards" {
  source = "./modules/dashboards"
  instance_ids = module.base.instance_ids
}
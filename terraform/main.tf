terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "app_service" {
  source = "./modules/app_service"

  service_name               = var.service_name
  environment                = var.environment
  vpc_id                     = var.vpc_id
  private_subnet_ids         = var.private_subnet_ids
  vpc_tag_filters            = var.vpc_tag_filters
  public_subnet_tag_filters  = var.public_subnet_tag_filters
  private_subnet_tag_filters = var.private_subnet_tag_filters

  container_port    = var.container_port
  desired_count     = var.desired_count
  cpu               = var.cpu
  memory            = var.memory
  image_tag         = var.image_tag
  health_check_path = var.health_check_path
  assign_public_ip  = var.assign_public_ip
  tags              = var.tags
}

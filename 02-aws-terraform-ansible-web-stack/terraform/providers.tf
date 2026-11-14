terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


provider "aws" {
  region = "eu-north-1"
  default_tags {
    tags = { Project = "vprofile-lab", Environment = "lab", ManagedBy = "Terraform" }
  }
}
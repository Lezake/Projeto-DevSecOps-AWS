terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket         = "lezake-tfstate-devsecops-908027385183"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    use_path_style = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "Terraform"
      Project     = "devsecops-aws-pipeline"
    }
  }
}

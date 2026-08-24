terraform {
  required_version = ">= 1.10.0"

  # AQUI ESTÁ O NOVO BLOCO
  backend "s3" {
    bucket         = "lezake-tfstate-devsecops-908027385183"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    use_path_style = true # Recomendação atual para S3
    # NOTA CORPORATIVA: Não usamos 'dynamodb_table' aqui pois o Terraform 1.10+
    # gerencia o locking nativamente no S3 usando APIs de condicional PUT.
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
      Project     = "iac-pipeline-portfolio"
    }
  }
}

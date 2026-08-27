variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# --- VPC ---
resource "aws_vpc" "main" {
  # checkov:skip=CKV2_AWS_11: "VPC flow logs disabled to keep architecture strictly within Free Tier limits"
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "devsecops-vpc"
  }
}

# --- Default Security Group Restrictive (Checkov CKV2_AWS_12) ---
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

# --- Subnet ---
resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130: "Public IP required since Free Tier architecture does not utilize a NAT Gateway"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true # Necessário para instâncias em subnet pública
  availability_zone       = "us-east-1a" # Forçado para evitar o erro de capacidade na zona 1e

  tags = {
    Name = "devsecops-public-subnet"
  }
}

# --- Internet Gateway & Roteamento ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devsecops-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "devsecops-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Saídas (Outputs) ---
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

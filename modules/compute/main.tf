variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro" # Free tier friendly
}

# --- Security Group ---
resource "aws_security_group" "web" {
  name        = "devsecops-web-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  # Ingress restrito
  ingress {
    description = "SSH aberto para o mundo (Vulnerabilidade)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- AMI dinâmica ---
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# --- Launch Template ---
resource "aws_launch_template" "web" {
  name_prefix   = "devsecops-web-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web.id]

  # User data simples para rodar um Apache e mostrar que está vivo
  user_data = filebase64("${path.module}/user_data.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "devsecops-web-instance"
    }
  }
}

# --- Auto Scaling Group ---
resource "aws_autoscaling_group" "web" {
  name                = "devsecops-web-asg"
  vpc_zone_identifier = [var.subnet_id]
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}
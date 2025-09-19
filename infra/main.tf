terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "cicd_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "cicd-health-dashboard-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "cicd_igw" {
  vpc_id = aws_vpc.cicd_vpc.id

  tags = {
    Name = "cicd-health-dashboard-igw"
  }
}

# Public Subnet
resource "aws_subnet" "cicd_public_subnet" {
  vpc_id                  = aws_vpc.cicd_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "cicd-health-dashboard-public-subnet"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "cicd_public_rt" {
  vpc_id = aws_vpc.cicd_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cicd_igw.id
  }

  tags = {
    Name = "cicd-health-dashboard-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "cicd_public_rta" {
  subnet_id      = aws_subnet.cicd_public_subnet.id
  route_table_id = aws_route_table.cicd_public_rt.id
}

# Security Group for EC2 instance
resource "aws_security_group" "cicd_sg" {
  name_prefix = "cicd-health-dashboard-sg"
  vpc_id      = aws_vpc.cicd_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Frontend port
  ingress {
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Backend port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL port (for internal access)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cicd-health-dashboard-sg"
  }
}

# Key Pair for EC2 access
resource "aws_key_pair" "cicd_key" {
  key_name   = "cicd-health-dashboard-key"
  public_key = file(var.public_key_path)
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "cicd_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.cicd_key.key_name
  vpc_security_group_ids = [aws_security_group.cicd_sg.id]
  subnet_id              = aws_subnet.cicd_public_subnet.id

  user_data = templatefile("${path.module}/user_data.sh", {
    app_name = var.app_name
  })

  tags = {
    Name = "cicd-health-dashboard-instance"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
}

# Elastic IP for static public IP
resource "aws_eip" "cicd_eip" {
  instance = aws_instance.cicd_instance.id
  domain   = "vpc"

  tags = {
    Name = "cicd-health-dashboard-eip"
  }

  depends_on = [aws_internet_gateway.cicd_igw]
}

# RDS Subnet Group
resource "aws_db_subnet_group" "cicd_db_subnet_group" {
  name       = "cicd-db-subnet-group"
  subnet_ids = [aws_subnet.cicd_public_subnet.id]

  tags = {
    Name = "cicd-db-subnet-group"
  }
}

# RDS Security Group
resource "aws_security_group" "cicd_rds_sg" {
  name_prefix = "cicd-rds-sg"
  vpc_id      = aws_vpc.cicd_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.cicd_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cicd-rds-sg"
  }
}

# RDS Instance (PostgreSQL)
resource "aws_db_instance" "cicd_postgres" {
  identifier = "cicd-health-dashboard-db"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "cicd"
  username = "postgres"
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.cicd_rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.cicd_db_subnet_group.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "cicd-health-dashboard-db"
  }
}

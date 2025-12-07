terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "ap-south-1"
}



data "aws_vpc" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

/*resource "aws_key_pair" "mainkey" {
  key_name   = "mainkey"
  public_key = var.key_name
}*/

resource "aws_security_group" "ec2_sg" {
  name   = "ec2-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecom-ec2-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecom-rds-sg"
  }
}

resource "aws_subnet" "new_az" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.48.0/20"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecom-new-subnet-ap-south-1a"
  }
}


resource "aws_db_subnet_group" "db_subnets" {
  name       = "ecom-db-subnet-group"
  subnet_ids = [
    "subnet-0d2ed36519468a06b",  # existing ap-south-1b
    aws_subnet.new_az.id         # new ap-south-1a
  ]

  tags = {
    Name = "ecom-db-subnet-group"
  }
}


resource "aws_db_instance" "ecom_db" {
  identifier              = "ecom-db"
  allocated_storage       = var.allocated_storage
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false
  skip_final_snapshot     = true

  tags = {
    Name = "ecom-rds"
  }
}


resource "aws_instance" "ecom_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type

  subnet_id              = aws_subnet.new_az.id
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.key_name
  

  tags = {
    Name = "ecom-ec2"
  }
}

output "ec2_public_ip" {
  value = aws_instance.ecom_ec2.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.ecom_db.address
}


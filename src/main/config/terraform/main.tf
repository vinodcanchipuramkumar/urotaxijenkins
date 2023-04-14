terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "urotaxi-tfstate-bucket1"
    region = "ap-south-1"
    key = "terraform.tfstate"
    dynamodb_table = "urotaxi-terraform-lock"
  }
}
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "urotaxvpc" {
  cidr_block = var.urotaxvpc_cidr
  tags = {
    "Name" = "urotaxivpc"
  }
}
resource "aws_subnet" "urotaxipubsn1" {
  cidr_block = var.urotaxvpc_pubsn1
  vpc_id     = aws_vpc.urotaxvpc.id
  tags = {
    "Name" = "urotaxipubsn1"
  }
  availability_zone = "ap-south-1a"
}


resource "aws_subnet" "urotaxiprvsn3" {
  cidr_block = var.urotaxvpc_prvsn3
  vpc_id     = aws_vpc.urotaxvpc.id
  tags = {
    "Name" = "urotaxiprvsn3"
  }
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "urotaxiprvsn4" {
  cidr_block = var.urotaxvpc_prvsn4
  vpc_id     = aws_vpc.urotaxvpc.id
  tags = {
    "Name" = "urotaxiprvsn4"
  }
  availability_zone = "ap-south-1b"
}
resource "aws_internet_gateway" "urotaxiig" {
  vpc_id = aws_vpc.urotaxvpc.id
  tags = {
    "Name" = "urotaxig"
  }
}

resource "aws_route_table" "urotaxiigrt" {
  vpc_id = aws_vpc.urotaxvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.urotaxiig.id
  }
  tags = {
    "Name" = "urotaxiigrt"
  }
}
resource "aws_route_table_association" "urotaxiigrtassociation" {
  route_table_id = aws_route_table.urotaxiigrt.id
  subnet_id      = aws_subnet.urotaxipubsn1.id
}

resource "aws_security_group" "urotaxjavaserversg" {
  vpc_id = aws_vpc.urotaxvpc.id
  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "urotaxijavaserversg"
  }
}

resource "aws_security_group" "urotaxdbsg" {
  vpc_id = aws_vpc.urotaxvpc.id
  ingress {
    from_port   = "3306"
    to_port     = "3306"
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "urotaxidbsg"
  }
}

resource "aws_db_subnet_group" "urotaxidbsubnetgrp" {
    name = "urotaxidbsubnetgrp"
    subnet_ids = [aws_subnet.urotaxiprvsn3.id, aws_subnet.urotaxiprvsn4.id]
    tags = {
      "Name" = "urotaxidbsubnetgroup"
    }
}

resource "aws_db_instance" "urotaxidb" {
  vpc_security_group_ids = [aws_security_group.urotaxdbsg.id]
  allocated_storage = 10
  db_name = "urotaxidb"
  engine = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_type
  username = var.db_username
  password = var.db_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.urotaxidbsubnetgrp.name
}

resource "aws_key_pair" "urotaxikp" {
  key_name = "urotaxikey"
  public_key = var.urotaxi_public_key
}

resource "aws_instance" "urotaxiec2" {
  vpc_security_group_ids = [aws_security_group.urotaxjavaserversg.id]
  subnet_id = aws_subnet.urotaxipubsn1.id
  ami=var.ami
  key_name = aws_key_pair.urotaxikp.key_name
  instance_type = var.instance_shape  
  associate_public_ip_address = true
}







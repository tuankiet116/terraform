terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-southeast-2"
  profile = "vti-aws"
}

resource "aws_vpc" "vti-do2502-DE000079-vpc-as2-001" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "vti-do2502-DE000079-sn-public-as2-001" {
  vpc_id            = aws_vpc.vti-do2502-DE000079-vpc-as2-001.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone_names[0]
  depends_on        = [aws_vpc.vti-do2502-DE000079-vpc-as2-001]
}

resource "aws_subnet" "vti-do2502-DE000079-sn-private-as2-001" {
  vpc_id            = aws_vpc.vti-do2502-DE000079-vpc-as2-001.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zone_names[0]
  depends_on        = [aws_vpc.vti-do2502-DE000079-vpc-as2-001]
}

resource "aws_internet_gateway" "vti-do2502-DE000079-igw-as2-001" {
  vpc_id     = aws_vpc.vti-do2502-DE000079-vpc-as2-001.id
  depends_on = [aws_vpc.vti-do2502-DE000079-vpc-as2-001]
}

resource "aws_eip" "vti-do2502-DE000079-eip-as2-001" {
  vpc = true
}

resource "aws_nat_gateway" "vti-do2502-DE000079-nat-as2-001" {
  connectivity_type = "public"
  allocation_id     = aws_eip.vti-do2502-DE000079-eip-as2-001.id
  subnet_id         = aws_subnet.vti-do2502-DE000079-sn-public-as2-001.id

  depends_on = [aws_internet_gateway.vti-do2502-DE000079-igw-as2-001, aws_eip.vti-do2502-DE000079-eip-as2-001]
}


resource "aws_route_table" "vti-do2502-DE000079-rt-public-as2-001" {
  vpc_id = aws_vpc.vti-do2502-DE000079-vpc-as2-001.id
  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.vti-do2502-DE000079-igw-as2-001.id
  }
  depends_on = [aws_vpc.vti-do2502-DE000079-vpc-as2-001, aws_internet_gateway.vti-do2502-DE000079-igw-as2-001]
}

resource "aws_route_table" "vti-do2502-DE000079-rt-private-as2-001" {
  vpc_id = aws_vpc.vti-do2502-DE000079-vpc-as2-001.id
  route {
    cidr_block     = "10.0.2.0/24"
    nat_gateway_id = aws_nat_gateway.vti-do2502-DE000079-nat-as2-001.id
  }
  depends_on = [aws_vpc.vti-do2502-DE000079-vpc-as2-001, aws_nat_gateway.vti-do2502-DE000079-nat-as2-001]
}

resource "aws_security_group" "vti-do2502-DE000079-sg-public-as2-001" {
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vti-do2502-DE000079-vpc-as2-001.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vti-do2502-DE000079-sg-private-as2-001" {
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.vti-do2502-DE000079-vpc-as2-001.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "kp-private-as2-001" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "kp-private-as2-002" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "vti-do2502-DE000079-kp-public-as2-001" {
  public_key = tls_private_key.kp-private-as2-001.public_key_openssh
}

resource "aws_key_pair" "vti-do2502-DE000079-kp-private-as2-001" {
  public_key = tls_private_key.kp-private-as2-002.public_key_openssh
}

resource "aws_instance" "vti-do2502-DE000079-ec2-public-as2-001" {
  ami             = "ami-0a2e29e3b4fc39212"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.vti-do2502-DE000079-sn-public-as2-001.id
  key_name        = "vti-do2502-DE000079-keypair-as2-001"
  security_groups = ["vti-do2502-DE000079-sg-public-as2-001"]
  depends_on      = [aws_key_pair.vti-do2502-DE000079-kp-public-as2-001]
}

resource "aws_instance" "vti-do2502-DE000079-ec2-private-as2-001" {
  ami             = "ami-0a2e29e3b4fc39212"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.vti-do2502-DE000079-sn-private-as2-001.id
  key_name        = "vti-do2502-DE000079-keypair-as2-001"
  security_groups = ["vti-do2502-DE000079-sg-pivate-as2-001"]
  depends_on      = [aws_key_pair.vti-do2502-DE000079-kp-private-as2-001]
}

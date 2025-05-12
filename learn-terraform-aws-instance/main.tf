terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-southeast-2"
  profile = "vti-aws"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vti-do2502-DE000079-vpc-as2-001"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone_names[0]
  depends_on        = [aws_vpc.my_vpc]
  tags = {
    Name = "vti-do2502-DE000079-sn-public-as2-001"
  }
  
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zone_names[0]
  depends_on        = [aws_vpc.my_vpc]
  tags = {
    Name = "vti-do2502-DE000079-sn-private-as2-001"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id     = aws_vpc.my_vpc.id
  depends_on = [aws_vpc.my_vpc]
  
  tags = {
    Name = "vti-do2502-DE000079-igw-as2-001"
  }
}

resource "aws_eip" "elastic_ip" {
  tags = {
    Name = "vti-do2502-DE000079-eip-as2-001"
  }
}




resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "vti-do2502-DE000079-rt-public-as2-001"
  }

  depends_on = [aws_vpc.my_vpc, aws_internet_gateway.internet_gateway]
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_nat_gateway" "nat_gateway" {
  connectivity_type = "public"
  allocation_id     = aws_eip.elastic_ip.id
  subnet_id         = aws_subnet.public_subnet.id
  tags = {
    Name = "vti-do2502-DE000079-nat-as2-001"
  }

  depends_on = [aws_internet_gateway.internet_gateway, aws_eip.elastic_ip]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "vti-do2502-DE000079-rt-private-as2-001"
  }

  depends_on = [aws_vpc.my_vpc, aws_nat_gateway.nat_gateway]
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "public_security_group" {
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.my_vpc.id
  tags = {
    Name = "vti-do2502-DE000079-sg-public-as2-001"
  }
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

  depends_on = [aws_vpc.my_vpc]
}

resource "aws_security_group" "private_security_group" {
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.my_vpc.id
  tags = {
    Name = "vti-do2502-DE000079-sg-private-as2-001"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  depends_on = [aws_vpc.my_vpc]
}

resource "tls_private_key" "private_keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "public_keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "aws_public_kp" {
  public_key = tls_private_key.public_keypair.public_key_openssh
  tags = {
    Name = "vti-do2502-DE000079-kp-private-as2-001"
  }
}

resource "aws_key_pair" "aws_private_kp" {
  public_key = tls_private_key.private_keypair.public_key_openssh
  tags = {
    Name = "vti-do2502-DE000079-kp-public-as2-001"
  }
}

resource "aws_instance" "public_instance" {
  ami             = "ami-0a2e29e3b4fc39212"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet.id
  key_name        = aws_key_pair.aws_public_kp.key_name
  security_groups = [aws_security_group.public_security_group.id]
  tags = {
    Name = "vti-do2502-DE000079-ec2-public-as2-001"
  }
  depends_on      = [aws_key_pair.aws_public_kp]
}

resource "aws_instance" "private_instance" {
  ami             = "ami-0a2e29e3b4fc39212"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnet.id
  key_name        = aws_key_pair.aws_private_kp.key_name
  security_groups = [aws_security_group.private_security_group.id]
  tags = {
    Name = "vti-do2502-DE000079-ec2-private-as2-001"
  }
  depends_on      = [aws_key_pair.aws_private_kp]
}

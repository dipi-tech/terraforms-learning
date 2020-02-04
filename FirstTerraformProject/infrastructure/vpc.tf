provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
  }
}

resource "aws_vpc" "prod_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "Prod-VPC"
  }
}

resource "aws_subnet" "public_subnet1" {
  cidr_block        = var.public_subnet1_cidr_block
  vpc_id            = aws_vpc.prod_vpc.id
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Prod-Public-Subnet-1"
  }
}

resource "aws_subnet" "public_subnet2" {
  cidr_block        = var.public_subnet2_cidr_block
  vpc_id            = aws_vpc.prod_vpc.id
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Prod-Public-Subnet-2"
  }
}

resource "aws_subnet" "public_subnet3" {
  cidr_block        = var.public_subnet3_cidr_block
  vpc_id            = aws_vpc.prod_vpc.id
  availability_zone = "ap-south-1c"
  tags = {
    Name = "Prod-Public-Subnet-3"
  }
}

resource "aws_subnet" "private_subnet1" {
  cidr_block        = var.private_subnet1_cidr_block
  vpc_id            = aws_vpc.prod_vpc.id
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Prod-Private-Subnet-1"
  }
}

resource "aws_subnet" "private_subnet2" {
  cidr_block        = var.private_subnet2_cidr_block
  vpc_id            = aws_vpc.prod_vpc.id
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Prod-Private-Subnet-2"
  }
}

resource "aws_subnet" "private_subnet3" {
  cidr_block        = var.private_subnet3_cidr_block
  vpc_id            = aws_vpc.prod_vpc.id
  availability_zone = "ap-south-1c"
  tags = {
    Name = "Prod-Private-Subnet-3"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.prod_vpc.id
  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.prod_vpc.id
  tags = {
    Name = "Private-Route-Table"
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet1.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet2.id
}

resource "aws_route_table_association" "public_subnet_3_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet3.id
}

resource "aws_route_table_association" "private_subnet_1_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet1.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet2.id
}

resource "aws_route_table_association" "private_subnet_3_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet3.id
}

resource "aws_eip" "elastic_ip_for_nat_gateway" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"
  tags = {
    Name = "PROD EIP"
  }
}

resource "aws_nat_gateway" "prod_nat_gateway" {
  allocation_id = aws_eip.elastic_ip_for_nat_gateway.id
  subnet_id     = aws_subnet.public_subnet1.id

  depends_on = [aws_eip.elastic_ip_for_nat_gateway]

  tags = {
    Name = "Prod-Nat-Gateway"
  }
}

resource "aws_route" "nat_gateway_route" {
  route_table_id         = aws_route_table.private_route_table.id
  nat_gateway_id         = aws_nat_gateway.prod_nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_internet_gateway" "prod_igw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "Prod-Internet-GW"
  }
}

resource "aws_route" "public_internet_gateway_route" {
  route_table_id         = aws_route_table.public_route_table.id
  gateway_id             = aws_internet_gateway.prod_igw.id
  destination_cidr_block = "0.0.0.0/0"
}


# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc"
    Owner = "zili"
  }
}

resource "aws_internet_gateway" "igw" { 
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "igw"
        Owner = "zili"
    }
}

# Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-1"
    Owner = "zili"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-2"
    Owner = "zili"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
    Owner = "zili"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
    Owner = "zili"
  }
}

resource "aws_eip" "nat" {
  domain   = "vpc"

  tags = {
    Name = "eip"
    Owner = "zili"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
  connectivity_type = "public"

  tags = {
    Name = "natgw"
    Owner = "zili"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "privateroute" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private"
    Owner = "zili"
  }
}

resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
    Owner = "zili"
  }
}

resource "aws_route_table_association" "privateassociation_a" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.privateroute.id
}
resource "aws_route_table_association" "privateassociation_b" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.privateroute.id
}
resource "aws_route_table_association" "publicassociation_a" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.publicroute.id
}
resource "aws_route_table_association" "publicassociation_b" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.publicroute.id
}
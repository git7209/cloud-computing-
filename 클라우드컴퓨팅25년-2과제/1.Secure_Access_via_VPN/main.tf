# VPC
resource "aws_vpc" "ws_vpn_vpc" {
  cidr_block           = "10.99.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ws-vpn-vpc"
  }
}

# Subnets
## Public Subnets
resource "aws_subnet" "ws_public_subnet_a" {
  vpc_id            = aws_vpc.ws_vpn_vpc.id
  cidr_block        = "10.99.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "ws-public-subnet-a"
  }
}

resource "aws_subnet" "ws_public_subnet_b" {
  vpc_id            = aws_vpc.ws_vpn_vpc.id
  cidr_block        = "10.99.1.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "ws-public-subnet-b"
  }
}

## Private Subnets
resource "aws_subnet" "ws_private_subnet_a" {
  vpc_id            = aws_vpc.ws_vpn_vpc.id
  cidr_block        = "10.99.10.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "ws-private-subnet-a"
  }
}

resource "aws_subnet" "ws_private_subnet_b" {
  vpc_id            = aws_vpc.ws_vpn_vpc.id
  cidr_block        = "10.99.11.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "ws-private-subnet-b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ws_igw" {
  vpc_id = aws_vpc.ws_vpn_vpc.id

  tags = {
    Name = "ws-igw"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "ws_nat_eip_a" {
  domain = "vpc"
}

resource "aws_eip" "ws_nat_eip_b" {
  domain = "vpc"
}

# NAT Gateways
resource "aws_nat_gateway" "ws_nat_gw_a" {
  allocation_id = aws_eip.ws_nat_eip_a.id
  subnet_id     = aws_subnet.ws_public_subnet_a.id

  tags = {
    Name = "ws-nat-gw-a"
  }

  depends_on = [aws_internet_gateway.ws_igw]
}

resource "aws_nat_gateway" "ws_nat_gw_b" {
  allocation_id = aws_eip.ws_nat_eip_b.id
  subnet_id     = aws_subnet.ws_public_subnet_b.id

  tags = {
    Name = "ws-nat-gw-b"
  }

  depends_on = [aws_internet_gateway.ws_igw]
}

# Route Tables
## Public Route Table
resource "aws_route_table" "ws_public_rt" {
  vpc_id = aws_vpc.ws_vpn_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ws_igw.id
  }

  tags = {
    Name = "ws-public-rt"
  }
}

## Private Route Tables
resource "aws_route_table" "ws_private_rt_a" {
  vpc_id = aws_vpc.ws_vpn_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ws_nat_gw_a.id
  }

  tags = {
    Name = "ws-private-rt-a"
  }
}

resource "aws_route_table" "ws_private_rt_b" {
  vpc_id = aws_vpc.ws_vpn_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ws_nat_gw_b.id
  }

  tags = {
    Name = "ws-private-rt-b"
  }
}

# Route Table Associations
## Public Subnets
resource "aws_route_table_association" "ws_public_subnet_a_assoc" {
  subnet_id      = aws_subnet.ws_public_subnet_a.id
  route_table_id = aws_route_table.ws_public_rt.id
}

resource "aws_route_table_association" "ws_public_subnet_b_assoc" {
  subnet_id      = aws_subnet.ws_public_subnet_b.id
  route_table_id = aws_route_table.ws_public_rt.id
}

## Private Subnets
resource "aws_route_table_association" "ws_private_subnet_a_assoc" {
  subnet_id      = aws_subnet.ws_private_subnet_a.id
  route_table_id = aws_route_table.ws_private_rt_a.id
}

resource "aws_route_table_association" "ws_private_subnet_b_assoc" {
  subnet_id      = aws_subnet.ws_private_subnet_b.id
  route_table_id = aws_route_table.ws_private_rt_b.id
}

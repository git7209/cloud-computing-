# VPC
resource "aws_vpc" "order_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "order-vpc"
  }
}

# Subnets
## Public Subnets
resource "aws_subnet" "order_public_subnet_a" {
  vpc_id            = aws_vpc.order_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "order-public-subnet-a"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "order_public_subnet_b" {
  vpc_id            = aws_vpc.order_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "order-public-subnet-b"
    "kubernetes.io/role/elb" = "1"
  }
}

## Private Subnets
resource "aws_subnet" "order_private_subnet_a" {
  vpc_id            = aws_vpc.order_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "order-private-subnet-a"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "order_private_subnet_b" {
  vpc_id            = aws_vpc.order_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "order-private-subnet-b"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "order_igw" {
  vpc_id = aws_vpc.order_vpc.id

  tags = {
    Name = "order-igw"
  }
}

# NAT Gateways
resource "aws_eip" "order_nat_eip_a" {
  domain = "vpc"
}

resource "aws_nat_gateway" "order_nat_gw_a" {
  allocation_id = aws_eip.order_nat_eip_a.id
  subnet_id     = aws_subnet.order_public_subnet_a.id

  tags = {
    Name = "order-nat-gw-a"
  }
  
  depends_on = [aws_internet_gateway.order_igw]
}

resource "aws_eip" "order_nat_eip_b" {
  domain = "vpc"
}

resource "aws_nat_gateway" "order_nat_gw_b" {
  allocation_id = aws_eip.order_nat_eip_b.id
  subnet_id     = aws_subnet.order_public_subnet_b.id

  tags = {
    Name = "order-nat-gw-b"
  }

  depends_on = [aws_internet_gateway.order_igw]
}

# Route Tables
## Public Route Table
resource "aws_route_table" "order_public_rt" {
  vpc_id = aws_vpc.order_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.order_igw.id
  }

  tags = {
    Name = "order-public-rt"
  }
}

## Private Route Tables
resource "aws_route_table" "order_private_rt_a" {
  vpc_id = aws_vpc.order_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.order_nat_gw_a.id
  }

  tags = {
    Name = "order-private-rt-a"
  }
}

resource "aws_route_table" "order_private_rt_b" {
  vpc_id = aws_vpc.order_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.order_nat_gw_b.id
  }

  tags = {
    Name = "order-private-rt-b"
  }
}

# Route Table Associations
resource "aws_route_table_association" "order_public_subnet_a_assoc" {
  subnet_id      = aws_subnet.order_public_subnet_a.id
  route_table_id = aws_route_table.order_public_rt.id
}

resource "aws_route_table_association" "order_public_subnet_b_assoc" {
  subnet_id      = aws_subnet.order_public_subnet_b.id
  route_table_id = aws_route_table.order_public_rt.id
}

resource "aws_route_table_association" "order_private_subnet_a_assoc" {
  subnet_id      = aws_subnet.order_private_subnet_a.id
  route_table_id = aws_route_table.order_private_rt_a.id
}

resource "aws_route_table_association" "order_private_subnet_b_assoc" {
  subnet_id      = aws_subnet.order_private_subnet_b.id
  route_table_id = aws_route_table.order_private_rt_b.id
}

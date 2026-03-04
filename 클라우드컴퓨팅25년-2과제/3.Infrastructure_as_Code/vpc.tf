resource "aws_vpc" "korea_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "korea-vpc"
    Project = "KoreaSkills"
  }
}

resource "aws_subnet" "korea_public_subnet_a" {
  vpc_id                  = aws_vpc.korea_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "korea-public-subnet-a"
    Project = "KoreaSkills"
  }
}

resource "aws_internet_gateway" "korea_igw" {
  vpc_id = aws_vpc.korea_vpc.id

  tags = {
    Name    = "korea-igw"
    Project = "KoreaSkills"
  }
}

resource "aws_route_table" "korea_public_rt" {
  vpc_id = aws_vpc.korea_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.korea_igw.id
  }

  tags = {
    Name    = "korea-public-rt"
    Project = "KoreaSkills"
  }
}

resource "aws_route_table_association" "korea_public_rt_assoc" {
  subnet_id      = aws_subnet.korea_public_subnet_a.id
  route_table_id = aws_route_table.korea_public_rt.id
}

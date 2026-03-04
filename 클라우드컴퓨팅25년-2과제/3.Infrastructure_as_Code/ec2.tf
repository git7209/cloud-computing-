data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "korea_instance" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.korea_public_subnet_a.id
  iam_instance_profile = aws_iam_instance_profile.korea_profile.name

  root_block_device {
    encrypted = true
  }

  tags = {
    Name    = "korea-instance"
    Project = "KoreaSkills"
  }
}

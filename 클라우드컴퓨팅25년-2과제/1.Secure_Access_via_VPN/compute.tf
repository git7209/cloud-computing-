# EC2 Instances

# Get Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# User Data Script
locals {
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "Welcome to the ws portal" > /var/www/html/index.html
  EOF
}

# Web Server A
resource "aws_instance" "ws_web_a" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.ws_private_subnet_a.id

  vpc_security_group_ids = [aws_security_group.ws_web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ws_ec2_ssm_profile.name

  user_data = local.user_data

  tags = {
    Name = "ws-web-a"
  }
}

# Web Server B
resource "aws_instance" "ws_web_b" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.ws_private_subnet_b.id

  vpc_security_group_ids = [aws_security_group.ws_web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ws_ec2_ssm_profile.name

  user_data = local.user_data

  tags = {
    Name = "ws-web-b"
  }
}

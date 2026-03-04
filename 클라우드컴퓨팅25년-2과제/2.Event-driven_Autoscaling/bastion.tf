# Bastion Security Group
resource "aws_security_group" "order_bastion_sg" {
  name        = "order-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.order_vpc.id

  # Inbound Rules (Assume user wants to connect via SSH or SSM, allow SSH from anywhere is risky but common for bastion if IP restricted, 
  # but here no restriction mentioned. I'll stick to no inbound if using SSM, or standard SSH if user needs keys.
  # The prompt says "Access EKS cluster via Bastion", usually implies kubectl on bastion.
  # If using SSM, no inbound ports needed. I will rely on SSM or Instance Connect.)
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "order-bastion-sg"
  }
}

# Bastion IAM Role
resource "aws_iam_role" "order_bastion_role" {
  name = "order-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "order_bastion_admin_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.order_bastion_role.name
}

resource "aws_iam_instance_profile" "order_bastion_profile" {
  name = "order-bastion-profile"
  role = aws_iam_role.order_bastion_role.name
}

# Bastion Instance
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "order_bastion" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.order_public_subnet_a.id

  vpc_security_group_ids = [aws_security_group.order_bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.order_bastion_profile.name

  tags = {
    Name = "order-bastion"
  }
}

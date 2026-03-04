# Security Groups
## Web Server Security Group
resource "aws_security_group" "ws_web_sg" {
  name        = "ws-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.ws_vpn_vpc.id

  # Inbound Rules
  ingress {
    description = "Allow HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.ws_vpn_vpc.cidr_block]
  }
  
  # Allow traffic from Client VPN CIDR (This is required for VPN clients to access the web server)
  # Even though not explicitly mentioned in the PDF table, it is implied by "Web browser... connect to ws-web-a/b Private IP... index.html should show"
  ingress {
    description = "Allow HTTP from Client VPN CIDR"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.254.0.0/16"]
  }

  # Outbound Rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ws-web-sg"
  }
}

# IAM Role for EC2 (SSM Access)
resource "aws_iam_role" "ws_ec2_ssm_role" {
  name = "ws-ec2-ssm-role"

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

resource "aws_iam_role_policy_attachment" "ws_ec2_ssm_policy_attachment" {
  role       = aws_iam_role.ws_ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ws_ec2_ssm_profile" {
  name = "ws-ec2-ssm-profile"
  role = aws_iam_role.ws_ec2_ssm_role.name
}

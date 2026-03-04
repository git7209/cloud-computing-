resource "aws_iam_role" "korea_role" {
  name = "korea-role"

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

  tags = {
    Name    = "korea-role"
    Project = "KoreaSkills"
  }
}

resource "aws_iam_role_policy_attachment" "korea_ssm_policy" {
  role       = aws_iam_role.korea_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "korea_profile" {
  name = "korea-profile"
  role = aws_iam_role.korea_role.name
}

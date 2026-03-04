# EKS Cluster Role
resource "aws_iam_role" "order_cluster_role" {
  name = "order-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "order_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.order_cluster_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "order_cluster" {
  name     = "order-cluster"
  version  = "1.33" # Using 1.33 as requested by user
  role_arn = aws_iam_role.order_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.order_public_subnet_a.id,
      aws_subnet.order_public_subnet_b.id,
      aws_subnet.order_private_subnet_a.id,
      aws_subnet.order_private_subnet_b.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.order_cluster_policy]
}

# Node Group Role
resource "aws_iam_role" "order_node_role" {
  name = "order-node-role"

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

resource "aws_iam_role_policy_attachment" "order_node_policy_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.order_node_role.name
}

resource "aws_iam_role_policy_attachment" "order_node_policy_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.order_node_role.name
}

resource "aws_iam_role_policy_attachment" "order_node_policy_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.order_node_role.name
}

# Node Group
resource "aws_eks_node_group" "order_node_group" {
  cluster_name    = aws_eks_cluster.order_cluster.name
  node_group_name = "order-node-group"
  node_role_arn   = aws_iam_role.order_node_role.arn
  subnet_ids      = [
    aws_subnet.order_private_subnet_a.id,
    aws_subnet.order_private_subnet_b.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  
  # Using Amazon Linux 2 ( AL2_x86_64 ) is default.
  # If 1.33 supports AL2023, we can specify it, but AL2 is safer for general EKS compatibility unless specified otherwise.
  # The prompt mentioned "Binary verified on Amazon Linux 2023", so setting AMI type might be good if supported.
  # AMI Type AL2023_x86_64_STANDARD is supported in newer EKS versions.
  ami_type = "AL2023_x86_64_STANDARD" 

  depends_on = [
    aws_iam_role_policy_attachment.order_node_policy_worker,
    aws_iam_role_policy_attachment.order_node_policy_cni,
    aws_iam_role_policy_attachment.order_node_policy_registry,
  ]
}

# OIDC Provider
data "tls_certificate" "order_oidc_thumbprint" {
  url = aws_eks_cluster.order_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "order_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.order_oidc_thumbprint.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.order_cluster.identity[0].oidc[0].issuer
}

# Namespace
resource "kubernetes_namespace" "order" {
  metadata {
    name = "order"
  }
}

# IRSA for Application
data "aws_iam_policy_document" "order_sqs_policy" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl"]
    resources = [aws_sqs_queue.order_queue.arn]
  }
}

resource "aws_iam_policy" "order_sqs_access" {
  name   = "order-sqs-access"
  policy = data.aws_iam_policy_document.order_sqs_policy.json
}

data "aws_iam_policy_document" "order_sa_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.order_oidc_provider.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.order_oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:order:order-sa"]
    }
  }
}

resource "aws_iam_role" "order_sa_role" {
  name               = "order-sa-role"
  assume_role_policy = data.aws_iam_policy_document.order_sa_assume_role.json
}

resource "aws_iam_role_policy_attachment" "order_sa_policy_attach" {
  role       = aws_iam_role.order_sa_role.name
  policy_arn = aws_iam_policy.order_sqs_access.arn
}

resource "kubernetes_service_account" "order_sa" {
  metadata {
    name      = "order-sa"
    namespace = kubernetes_namespace.order.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.order_sa_role.arn
    }
  }
}

# KEDA Authentication TriggerAuthentication
resource "kubernetes_manifest" "keda_trigger_auth" {
  manifest = {
    apiVersion = "keda.sh/v1alpha1"
    kind       = "TriggerAuthentication"
    metadata = {
      name      = "keda-trigger-auth-aws-credentials"
      namespace = kubernetes_namespace.order.metadata[0].name
    }
    spec = {
      podIdentity = {
        provider = "aws-eks"
      }
    }
  }
}

# Deployment
resource "kubernetes_deployment" "order_processor" {
  metadata {
    name      = "order-processor"
    namespace = kubernetes_namespace.order.metadata[0].name
  }

  spec {
    replicas = 1 # Managed by KEDA later, but start with 1
    selector {
      match_labels = {
        app = "order-processor"
      }
    }

    template {
      metadata {
        labels = {
          app = "order-processor"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.order_sa.metadata[0].name
        container {
          image = "nginx:latest" # Placeholder image as requested
          name  = "order-processor"

          env {
            name  = "QUEUE_URL"
            value = aws_sqs_queue.order_queue.url
          }
          env {
            name  = "REGION_NAME"
            value = "ap-northeast-2"
          }
          
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# ScaledObject
resource "kubernetes_manifest" "order_scaled_object" {
  manifest = {
    apiVersion = "keda.sh/v1alpha1"
    kind       = "ScaledObject"
    metadata = {
      name      = "aws-sqs-queue-scaledobject"
      namespace = kubernetes_namespace.order.metadata[0].name
    }
    spec = {
      scaleTargetRef = {
        name = "order-processor"
      }
      minReplicaCount = 1
      maxReplicaCount = 10 
      triggers = [
        {
          type = "aws-sqs-queue"
          metadata = {
            queueURL        = aws_sqs_queue.order_queue.url
            queueLength     = "5"
            awsRegion       = "ap-northeast-2"
            identityOwner   = "pod"
          }
          authenticationRef = {
            name = "keda-trigger-auth-aws-credentials"
          }
        }
      ]
    }
  }
}

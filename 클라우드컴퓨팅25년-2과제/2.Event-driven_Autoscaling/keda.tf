resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  version          = "2.14.0" # Use a stable version

  set {
    name  = "operator.name"
    value = "keda-operator"
  }
  
  # Ensure EKS node group is ready before installing Helm charts
  depends_on = [aws_eks_node_group.order_node_group]
}

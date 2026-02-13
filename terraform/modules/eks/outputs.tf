#============================================ Outputs ============================================#
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.project_bedrock_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.project_bedrock_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data"
  value       = aws_eks_cluster.project_bedrock_cluster.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = aws_eks_cluster.project_bedrock_cluster.identity[0].oidc[0].issuer
}

output "node_group_arn" {
  description = "Node group ARN"
  value       = aws_eks_node_group.main.arn
}

output "kubeconfig" {
  description = "Kubectl config for the cluster"
  value = templatefile("${path.module}/templates/kubeconfig.tpl", {
    cluster_name = aws_eks_cluster.project_bedrock_cluster.name
    endpoint     = aws_eks_cluster.project_bedrock_cluster.endpoint
    cluster_ca   = aws_eks_cluster.project_bedrock_cluster.certificate_authority[0].data
    region       = "us-east-1"
  })
  sensitive = true
}

output "alb_controller_role_arn" {
  description = "ARN of the IAM role for ALB Controller"
  value       = aws_iam_role_policy_attachment.aws_load_balancer_controller.policy_arn
}

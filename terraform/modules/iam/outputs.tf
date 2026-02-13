output "iam_roles" {
  description = "IAM roles created for the EKS cluster and node groups"
  value = {
    eks_cluster_arn             = aws_iam_role.eks_cluster_role.arn
    eks_cluster_name            = aws_iam_role.eks_cluster_role.name
    eks_node_group_arn          = aws_iam_role.eks_node_group_role.arn
    eks_node_group_name         = aws_iam_role.eks_node_group_role.name
    developer_access_key_id     = aws_iam_access_key.bedrock_dev_view_key.id
    developer_secret_access_key = aws_iam_access_key.bedrock_dev_view_key.secret
    developer_iam_user_name     = aws_iam_user.bedrock_dev_view.name
  }
}
